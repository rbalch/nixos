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
        udiskie
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
    ];

    home.file = {
        ".config/hypr/hyprland.conf".source = configs/hyprland.conf;
        ".config/hypr/hyprpaper.conf".source = configs/hyprpaper.conf;
        ".config/waybar/config".source = configs/waybar.json;
        ".config/nixpkgs/config.nix".source = configs/config.nix;
        "Pictures/backgrounds/earth.jpg".source = backgrounds/earth.jpg;
        ".config/hypr/hypridle.conf".source = configs/hypr/hypridle.conf;
        ".config/hypr/hyprlock.conf".source = configs/hypr/hyprlock.conf;
        # vscode wayland font fix
        ".config/code-flags.conf".text = "--ozone-platform=wayland";
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
        userEmail = "ryan@balch.io";
        userName = "Ryan Balch";
        extraConfig = {
            core = { editor = "vim"; };
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
        theme = "tokyonight";
        background-opacity = 0.95;
        background-blur = true;
        window-width = 160;
        window-height = 70;
        keybind = [
        "super+c=copy_to_clipboard"
        "super+v=paste_from_clipboard"
        ];
    };
    };

}
