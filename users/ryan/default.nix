{ config, pkgs, ... }:

{
    home.username = "ryan";
    home.homeDirectory = "/home/ryan";
    home.stateVersion = "23.05";

    imports = [
        ./ssh.nix
        ./zsh.nix
    ];

    home.packages = with pkgs; [
        google-chrome
        lastpass-cli
        neofetch
        slack
        thefuck
        vscode

        (pkgs.writeShellScriptBin "docker-stop" ''
            #!/bin/bash
            docker stop $(docker ps -q)
        '')
    ];

    home.file = {
        ".config/hypr/hyprland.conf".source = configs/hyprland.conf;
    }

    programs.git = {
        enable = true;
        userEmail = "ryan@balch.io";
        userName = "Ryan Balch";
    };
}