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
    ];

    home.file = {
        # ".config/hypr/hyprland.conf".source = configs/hyprland.conf;
        ".config/hypr/hyprpaper.conf".source = configs/hyprpaper.conf;
        ".config/waybar/config".source = configs/waybar.json;
        ".config/nixpkgs/config.nix".source = configs/config.nix;
        "Pictures/backgrounds/earth.jpg".source = backgrounds/earth.jpg;
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

}
