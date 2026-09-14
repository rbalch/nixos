{ lib, pkgs, ... }:

let
    herdr = pkgs.callPackage ../../packages/herdr { };

    # Finish Home Manager's files and packages before downloading extra CLIs.
    # Run each installer in its own shell so a failure cannot abort activation.
    bootstrap = name: commands:
        let installer = pkgs.writeShellScript "bootstrap-${name}" ''
            set -euo pipefail
            export PATH=${lib.makeBinPath [ pkgs.nodejs_24 pkgs.bash pkgs.coreutils ]}:"$PATH"
            ${commands}
        '';
        in lib.hm.dag.entryAfter [ "linkGeneration" "installPackages" ] ''
            if [ ! -x "$HOME/.local/bin/${name}" ]; then
                if run ${installer}; then
                    :
                else
                    status=$?
                    printf '%s\n' "Warning: ${name} install failed (exit $status); the next rebuild will retry if it is still missing." >&2
                fi
            fi
        '';

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
    home.activation.claudeCodeBootstrap = bootstrap "claude" ''
        # Use full Node, as in the npx wrappers below. This also puts Node on
        # PATH for child commands launched by npm during the first boot.
        ${pkgs.nodejs_24}/bin/node \
            ${pkgs.nodejs_24}/lib/node_modules/npm/bin/npx-cli.js --yes \
            @anthropic-ai/claude-code@latest install latest
    '';

    # `pi update` handles later upgrades outside the Nix store.
    home.activation.piBootstrap = bootstrap "pi" ''
        ${pkgs.nodejs_24}/bin/node \
            ${pkgs.nodejs_24}/lib/node_modules/npm/bin/npm-cli.js \
            install -g --prefix "$HOME/.local" --ignore-scripts \
            @earendil-works/pi-coding-agent
    '';

    # Hide the managed shell so Grok does not try to edit Home Manager's .zshrc.
    # `grok update` handles later upgrades outside the Nix store.
    home.activation.grokBootstrap = bootstrap "grok" ''
        installer="$(${pkgs.coreutils}/bin/mktemp)"
        trap 'rm -f "$installer"' EXIT
        ${pkgs.curl}/bin/curl -fsSL \
            https://x.ai/cli/install.sh \
            -o "$installer"
        ${pkgs.coreutils}/bin/env \
            SHELL=/bin/false \
            GROK_BIN_DIR="$HOME/.local/bin" \
            PATH=${lib.makeBinPath [ pkgs.bash pkgs.coreutils pkgs.curl pkgs.gawk pkgs.gnugrep pkgs.gnused ]} \
            ${pkgs.bash}/bin/bash "$installer"
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
