{ config, lib, pkgs, hostName, ... }:

{
    home.username = "ryan";
    home.homeDirectory = "/home/ryan";
    home.stateVersion = "25.11";

    imports = [
        ./nvim.nix
        ./ssh.nix
        ./vscode.nix
        ./waybar.nix
        ./zsh.nix
    ];

    home.sessionVariables = {
        # claude-code: stay on Claude's own bleeding-edge channel but silence
        # the auto-updater nag. With the native install in ~/.local/bin/claude,
        # `claude update` is a deliberate command rather than a popup.
        DISABLE_AUTOUPDATER = "1";
    };

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

    home.packages = with pkgs; [
        awscli2
        code-cursor
        font-manager
        google-chrome
		google-cloud-sdk
        google-cursor
        hyprlock
        hypridle
        nwg-look
        pay-respects
        slack
		terraform
        nautilus
        udiskie
        awww
        wofi
        obsidian
        warp-terminal

        (pkgs.writeShellScriptBin "docker-stop" ''
            #!/bin/bash
            docker stop $(docker ps -q)
        '')

        # AI CLIs via npx — invoking via full nodejs to bypass nixpkgs bug
        # where npx's shebang points to nodejs-slim (missing /lib), causing
        # npm's globalDir lookup to crash with ENOENT on /lib.
        (pkgs.writeShellScriptBin "codex" ''
          #!/usr/bin/env bash
          exec ${pkgs.nodejs_24}/bin/node ${pkgs.nodejs_24}/lib/node_modules/npm/bin/npx-cli.js @openai/codex@latest "$@"
        '')

        (pkgs.writeShellScriptBin "gemini" ''
          #!/usr/bin/env bash
          exec ${pkgs.nodejs_24}/bin/node ${pkgs.nodejs_24}/lib/node_modules/npm/bin/npx-cli.js @google/gemini-cli@latest "$@"
        '')

        (pkgs.writeShellScriptBin "copy-to-bd-movie" ''
          #!/usr/bin/env bash
          set -euo pipefail

          src="''${1:?usage: copy-to-bd-movie <file>}"

          host="bd"
          dest_dir="~/other/movies"
          dest_path="''${dest_dir}/$(basename "$src")"

          ssh -o BatchMode=yes "$host" "mkdir -p $dest_dir" >/dev/null 2>&1 || {
            echo "Failed to reach $host or create $dest_dir"
            exit 1
          }

          rsync -a --partial --append-verify --info=progress2 \
            "$src" "''${host}:''${dest_path}"
        '')
    ] ++ lib.optionals (hostName == "cortex") [
        # orca-slicer wrapped to force XWayland — wxGLCanvas + NVIDIA + Wayland
        # passthrough leaves the 3D scene blank when models load. XWayland fixes it.
        # symlinkJoin avoids re-triggering the (very long) orca-slicer compile.
        # Cortex-only: the other hosts are headless (brain-dongle) or GPU-less.
        (pkgs.symlinkJoin {
            name = "orca-slicer-${pkgs.orca-slicer.version}";
            paths = [ pkgs.orca-slicer ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
                wrapProgram $out/bin/orca-slicer \
                    --set GDK_BACKEND x11 \
                    --set-default __GL_THREADED_OPTIMIZATIONS 0
            '';
        })
    ];

    home.file = {
        ".config/hypr/hyprland.conf".source = configs/hyprland.conf;
        ".config/nixpkgs/config.nix".source = configs/config.nix;
        "Pictures/backgrounds/earth.jpg".source = backgrounds/earth.jpg;
        ".config/hypr/hypridle.conf".source = configs/hypr/hypridle.conf;
        ".config/hypr/hyprlock.conf".source = configs/hypr/hyprlock.conf;
        ".config/hypr/snap.sh" = { source = configs/hypr/snap.sh; executable = true; };
        ".config/hypr/power-menu.sh" = { source = configs/hypr/power-menu.sh; executable = true; };
        ".config/hypr/super-t.sh" = { source = configs/hypr/super-t.sh; executable = true; };
        ".config/tmux/tmux.conf".source = configs/tmux.conf;
        # vscode wayland font fix
        ".config/code-flags.conf".text = "--ozone-platform=wayland";
        # chrome wayland stability — prevent crash on DPMS off / suspend
        ".config/chrome-flags.conf".text = ''
            --ozone-platform=wayland
            --enable-features=UseOzonePlatform
            --disable-features=WaylandWpColorManagerV1
            --disable-gpu-compositing
        '';
    };

    home.pointerCursor = {
        gtk.enable = true;
        package = pkgs.google-cursor;
        name = "GoogleDot-Blue";
        size = 28;
    };


    programs.git = {
        enable = true;
        lfs.enable = true;
        settings = {
            user.email = "ryan@balch.io";
            user.name = "Ryan Balch";
            core.editor = "vim";
        };
    };

    programs.password-store = {
        enable = true;
        settings = {
        PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
        };
    };

    programs.ghostty = {
    enable = true;
    settings = {
        font-family = "MesloLGS Nerd Font";
        font-size = 14;
        theme = "TokyoNight";
        background-opacity = 0.95;
        background-blur = true;
        window-width = 160;
        window-height = 70;
        # SUPER+C/V/N handled here (Hyprland doesn't claim these chords).
        # SUPER+T deliberately omitted: Hyprland's Super+T script handles new-window
        # vs new-tab routing, sending Ctrl+Shift+T to Ghostty for the tab case.
        keybind = [
        "super+c=copy_to_clipboard"
        "super+v=paste_from_clipboard"
        "super+n=new_window"
        "ctrl+alt+t=new_tab"
        ];
    };
    };

}
