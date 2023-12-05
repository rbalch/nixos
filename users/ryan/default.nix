{ config, pkgs, ... }:

{
    home.username = "ryan";
    home.homeDirectory = "/home/ryan";
    home.stateVersion = "23.11";

    imports = [
        ./ssh.nix
        ./zsh.nix
    ];

    home.packages = with pkgs; [
        google-chrome
        google-cursor
        kitty
        neofetch
        nwg-look
        slack
        thefuck
        udiskie
        vscode
        waybar
        wofi

        (pkgs.writeShellScriptBin "docker-stop" ''
            #!/bin/bash
            docker stop $(docker ps -q)
        '')
    ];

    home.file = {
        ".config/hypr/hyprland.conf".source = configs/hyprland.conf;
    };

    home.pointerCursor = {
        gtk.enable = true;
        # x11.enable = true;
        package = pkgs.google-cursor;
        name = "GoogleDot-Blue";
        size = 28;
    };

    programs.git = {
        enable = true;
        userEmail = "ryan@balch.io";
        userName = "Ryan Balch";
    };
}
