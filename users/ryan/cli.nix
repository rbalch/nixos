{ config, lib, pkgs, ... }:

let
    herdr = pkgs.callPackage ../../packages/herdr { };

    # Finish Home Manager's files and packages before downloading extra CLIs.
    # Run each installer in its own shell with a hard time limit so a failed
    # or stalled download cannot abort activation or hit the unit timeout.
    installerTimeout = 120;
    bootstrap = name: commands:
        let installer = pkgs.writeShellScript "bootstrap-${name}" ''
            set -euo pipefail
            export PATH=${lib.makeBinPath [ pkgs.nodejs_24 pkgs.bash pkgs.coreutils ]}:"$PATH"
            ${commands}
        '';
        in lib.hm.dag.entryAfter [ "linkGeneration" "installPackages" ] ''
            if [ ! -x "$HOME/.local/bin/${name}" ]; then
                if run ${pkgs.coreutils}/bin/timeout ${toString installerTimeout} ${installer}; then
                    :
                else
                    status=$?
                    if [ "$status" -eq 124 ]; then
                        printf '%s\n' "Warning: ${name} install timed out after ${toString installerTimeout}s; the next rebuild will retry if it is still missing." >&2
                    else
                        printf '%s\n' "Warning: ${name} install failed (exit $status); the next rebuild will retry if it is still missing." >&2
                    fi
                fi
            fi
        '';

    # Codex calls this after a turn. BEL lets the active terminal choose how
    # to alert instead of tying Codex to a desktop sound player.
    codex-notify = pkgs.writeShellScript "codex-notify" ''
        printf '\a' > /dev/tty
    '';

    # npx through full Node: the nixpkgs npx shebang points to nodejs-slim
    # (missing /lib), which crashes npm's globalDir lookup with ENOENT.
    npx = "${pkgs.nodejs_24}/bin/node ${pkgs.nodejs_24}/lib/node_modules/npm/bin/npx-cli.js";
in {
    home.username = "ryan";
    home.homeDirectory = "/home/ryan";

    # Native claude install lives in ~/.local/bin; ensure it's on PATH and beats
    # any stale wrappers from /etc/profiles.
    home.sessionPath = [ "$HOME/.local/bin" ];

    # Bootstrap claude-code into ~/.local/bin on first rebuild (or any rebuild
    # where the binary is missing). Subsequent rebuilds are silent no-ops.
    # Claude's own self-updater handles all upgrades after this.
    home.activation.claudeCodeBootstrap = bootstrap "claude" ''
        ${npx} --yes @anthropic-ai/claude-code@latest install latest
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
        ${pkgs.curl}/bin/curl -fsSL --connect-timeout 10 --max-time 60 \
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
        gh
        google-cloud-sdk
        herdr
        nodejs_24
        pay-respects
        ripgrep
        sshfs
        terraform
        tmux
        # AI CLIs via npx; their versions are not fixed by flake.lock.
        (pkgs.writeShellScriptBin "codex" ''
          exec ${npx} @openai/codex@latest \
            --config 'notify=["${codex-notify}"]' \
            "$@"
        '')
        (pkgs.writeShellScriptBin "gemini" ''
          exec ${npx} @google/gemini-cli@latest "$@"
        '')
    ];

    home.file = {
        # Lets ad-hoc nix-shell / nix repl on the legacy channel use unfree packages.
        ".config/nixpkgs/config.nix".source = ./configs/config.nix;
        ".config/tmux/tmux.conf".source = ./configs/tmux.conf;
        ".pi/agent/extensions/italic-yellow.ts".source = ./configs/pi/extensions/italic-yellow.ts;
    };

    # Identity (user.name/email) is per profile: users/ryan/default.nix for
    # personal hosts; ~/.gitconfig on work hosts (see docs/wsl.md).
    programs.git = {
        enable = true;
        lfs.enable = true;
        settings.core.editor = "vim";
    };
}
