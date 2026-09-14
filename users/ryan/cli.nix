{ lib, pkgs, ... }:

let
    herdr = pkgs.callPackage ../../packages/herdr { };

    # Codex calls this after a turn. BEL lets the active terminal choose how
    # to alert instead of tying Codex to a desktop sound player.
    codex-notify = pkgs.writeShellScript "codex-notify" ''
        printf '\a' > /dev/tty
    '';
in {
    # Native claude install lives in ~/.local/bin; ensure it's on PATH and beats
    # any stale wrappers from /etc/profiles.
    home.sessionPath = [ "$HOME/.local/bin" ];

    # Bootstrap claude-code into ~/.local/bin on first rebuild (or any rebuild
    # where the binary is missing). Subsequent rebuilds are silent no-ops.
    # Claude's own self-updater handles all upgrades after this.
    home.activation.claudeCodeBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -x "$HOME/.local/bin/claude" ]; then
            run ${pkgs.nodejs_24}/bin/npx --yes \
                @anthropic-ai/claude-code@latest install latest
        fi
    '';

    # Bootstrap pi into ~/.local on first rebuild. `pi update` handles later
    # upgrades while keeping the install outside the read-only Nix store.
    home.activation.piBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -x "$HOME/.local/bin/pi" ]; then
            run ${pkgs.nodejs_24}/bin/node \
                ${pkgs.nodejs_24}/lib/node_modules/npm/bin/npm-cli.js \
                install -g --prefix "$HOME/.local" --ignore-scripts \
                @earendil-works/pi-coding-agent
        fi
    '';

    # Bootstrap the official Grok Build client into ~/.local/bin on first
    # rebuild. `grok update` handles later upgrades. Hide the managed shell
    # from the installer so it does not try to edit Home Manager's .zshrc.
    home.activation.grokBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -x "$HOME/.local/bin/grok" ]; then
            installer="$(${pkgs.coreutils}/bin/mktemp)"
            run ${pkgs.curl}/bin/curl -fsSL \
                https://x.ai/cli/install.sh \
                -o "$installer"
            run ${pkgs.coreutils}/bin/env \
                SHELL=/bin/false \
                GROK_BIN_DIR="$HOME/.local/bin" \
                PATH=${lib.makeBinPath [ pkgs.bash pkgs.coreutils pkgs.curl pkgs.gawk pkgs.gnugrep pkgs.gnused ]} \
                ${pkgs.bash}/bin/bash "$installer"
            rm -f "$installer"
        fi
    '';

    home.packages = with pkgs; [
        awscli2
        cliamp
        fd
        google-cloud-sdk
        herdr
        nodejs_24
        pay-respects
        ripgrep
        terraform
        sshfs
        gh
        # AI CLIs via npx — invoking via full nodejs to bypass nixpkgs bug
        # where npx's shebang points to nodejs-slim (missing /lib), causing
        # npm's globalDir lookup to crash with ENOENT on /lib.
        (pkgs.writeShellScriptBin "codex" ''
          #!/usr/bin/env bash
          exec ${pkgs.nodejs_24}/bin/node \
            ${pkgs.nodejs_24}/lib/node_modules/npm/bin/npx-cli.js \
            @openai/codex@latest \
            --config 'notify=["${codex-notify}"]' \
            "$@"
        '')

        (pkgs.writeShellScriptBin "gemini" ''
          #!/usr/bin/env bash
          exec ${pkgs.nodejs_24}/bin/node ${pkgs.nodejs_24}/lib/node_modules/npm/bin/npx-cli.js @google/gemini-cli@latest "$@"
        '')

    ];
}
