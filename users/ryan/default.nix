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
        (pkgs.writeShellScriptBin "docker-stop" ''
            #!/bin/bash
            docker stop $(docker ps -q)
        '')
    ];

    programs.git = {
        enable = true;
        userEmail = "ryan@balch.io";
        userName = "Ryan Balch";
    };
}