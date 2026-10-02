{ lib, pkgs, ... }:

# Lean profile for the OpenRig service account (hosts/common/optional/openrig.nix).
# Deliberately unmanaged: ~/.tmux.conf and ~/.claude/settings.json. `rig setup`
# writes and owns both for this user.
let
    bootstrap = import ../../lib/hm-bootstrap.nix { inherit lib pkgs; };
    herdr = pkgs.callPackage ../../packages/herdr { };

    # Full Node rather than nodejs-slim; see the npx note in users/ryan/cli.nix.
    npm = "${pkgs.nodejs_24}/bin/node ${pkgs.nodejs_24}/lib/node_modules/npm/bin/npm-cli.js";
    npx = "${pkgs.nodejs_24}/bin/node ${pkgs.nodejs_24}/lib/node_modules/npm/bin/npx-cli.js";
in {
    home.username = "rig";
    home.homeDirectory = "/home/rig";
    home.stateVersion = "26.11";

    home.sessionPath = [ "$HOME/.local/bin" ];

    # OpenRig reaches other hosts with `ssh <host> rig ...`, a non-interactive
    # shell. bashrcExtra runs before Home Manager's interactive-only guard, so
    # ~/.local/bin (claude, rig) is on PATH for those calls too.
    programs.bash = {
        enable = true;
        bashrcExtra = ''
            export PATH="$HOME/.local/bin:$PATH"
        '';
    };

    home.packages = with pkgs; [
        fd
        gh
        git
        herdr
        jq
        nodejs_24
        ripgrep
        rsync
        tmux
        (pkgs.writeShellScriptBin "codex" ''
            exec ${npx} @openai/codex@latest "$@"
        '')
    ];

    home.activation.claudeCodeBootstrap = bootstrap "claude" { } ''
        ${npx} --yes @anthropic-ai/claude-code@latest install latest
    '';

    # Keep install scripts: better-sqlite3 fetches a prebuilt native module, or
    # compiles one with the toolchain below when no prebuilt matches.
    home.activation.openrigBootstrap = bootstrap "rig" {
        path = with pkgs; [ gcc gnumake python3 ];
    } ''
        ${npm} install -g --prefix "$HOME/.local" @openrig/cli
    '';

    # TODO: pi and grok bootstraps (copy from users/ryan/cli.nix) when those seats are wanted.

    programs.git = {
        enable = true;
        lfs.enable = true;
        # TODO: identity for agent commits, e.g. user.name = "ryan (rig@brain-dongle)".
    };
}
