{ lib, pkgs, hostName, ... }:

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
    # Same interactive shell as ryan (aliases, oh-my-zsh, p10k, fzf, direnv).
    imports = [ ../ryan/zsh.nix ];

    home.username = "rig";
    home.homeDirectory = "/home/rig";
    home.stateVersion = "26.11";

    home.sessionPath = [ "$HOME/.local/bin" ];

    # Login shell is zsh, whose ~/.zshenv sources home.sessionPath for every
    # shell, interactive or not. Bash is kept for anything that calls it
    # explicitly: bashrcExtra runs before Home Manager's interactive-only
    # guard, so ~/.local/bin (claude, rig) is on PATH there too.
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
    ] ++ lib.optionals (hostName != "sparq-lappy") [
        # Personal-token hosts only; work runs Claude alone on sparq-lappy.
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

    # rig-to-rig SSH for OpenRig cross-host commands (`rig host add ... --target rig-*`).
    # Each rig user needs its own key: `ssh-keygen -t ed25519` as rig, then add
    # the public key to users.users.rig.openssh.authorizedKeys on the other host.
    programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
            "*" = {
                forwardAgent = false;
                hashKnownHosts = true;
            };
            # Work GitHub, same alias as ryan's (users/ryan/ssh.nix), but rig's own
            # key so agent access can be revoked on its own. Clone work repos
            # as git@github.sparq:org/repo.
            "github.sparq" = {
                hostname = "github.com";
                user = "git";
                identityFile = "~/.ssh/github-sparq";
                identitiesOnly = true;
            };
            "rig-bd" = {
                # sparq-lappy resolves bd by name, the same way its reverse tunnel does.
                hostname = if hostName == "sparq-lappy" then "bd.braindongle.com" else "10.13.37.42";
                user = "rig";
                identityFile = "~/.ssh/id_ed25519";
            };
            # sparq-lappy cannot accept inbound SSH; its reverse tunnel publishes
            # its sshd on bd's loopback port 2222 (hosts/sparq-lappy/default.nix).
            "rig-lappy" = {
                hostname = "localhost";
                port = 2222;
                user = "rig";
                identityFile = "~/.ssh/id_ed25519";
                # localhost:2222 would otherwise collide with other loopback known_hosts entries.
                HostKeyAlias = "sparq-lappy";
            } // lib.optionalAttrs (hostName != "brain-dongle") { proxyJump = "rig-bd"; };
        };
    };

    programs.git = {
        enable = true;
        lfs.enable = true;
        # Agent commits name the box. Work email on sparq-lappy: its repos are work repos.
        settings.user = {
            name = "Ryan Balch (rig@${hostName})";
            email = if hostName == "sparq-lappy" then "ryan.balch@teamsparq.com" else "ryan@balch.io";
        };
    };
}
