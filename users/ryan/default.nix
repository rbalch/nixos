{ config, pkgs, ... }:

{
    home.username = "ryan";
    home.homeDirectory = "/home/ryan";
    home.stateVersion = "23.11";

    imports = [
        ./ssh.nix
        ./vscode.nix
        ./waybar.nix
        ./zsh.nix
        ../../modules/kitty
    ];

    home.packages = with pkgs; [
        awscli2
        code-cursor
        font-manager
        google-chrome
		google-cloud-sdk
        google-cursor
        hyprlock
        hypridle
        kitty
        neofetch
        nwg-look
        pay-respects
        slack
		terraform
        nautilus
        udiskie
        swww
        wofi

        (pkgs.writeShellScriptBin "docker-stop" ''
            #!/bin/bash
            docker stop $(docker ps -q)
        '')

        # OpenAI Codex CLI via npx (latest)
        (pkgs.writeShellScriptBin "codex" ''
          #!/usr/bin/env bash
          exec ${pkgs.nodejs_20}/bin/npx @openai/codex@latest "$@"
        '')

        # Gemini-CLI via npx (latest)
        (pkgs.writeShellScriptBin "gemini" ''
          #!/usr/bin/env bash
          exec ${pkgs.nodejs_20}/bin/npx @google/gemini-cli@latest "$@"
        '')

        # Claude CLI via npx (latest)
        (pkgs.writeShellScriptBin "claude" ''
          #!/usr/bin/env bash
          exec ${pkgs.nodejs_20}/bin/npx @anthropic-ai/claude-code@latest "$@"
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
    ];

    home.file = {
        ".config/hypr/hyprland.conf".source = configs/hyprland.conf;
        ".config/waybar/config".source = configs/waybar.json;
        ".config/nixpkgs/config.nix".source = configs/config.nix;
        "Pictures/backgrounds/earth.jpg".source = backgrounds/earth.jpg;
        ".config/hypr/hypridle.conf".source = configs/hypr/hypridle.conf;
        ".config/hypr/hyprlock.conf".source = configs/hypr/hyprlock.conf;
        ".config/hypr/snap-right.sh" = { source = configs/hypr/snap-right.sh; executable = true; };
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
        keybind = [
        "super+c=copy_to_clipboard"
        "super+v=paste_from_clipboard"
        "super+t=new_tab"
        ];
    };
    };

}
