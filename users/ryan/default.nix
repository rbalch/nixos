{ config, pkgs, ... }:

{
    home.username = "ryan";
    home.homeDirectory = "/home/ryan";

    imports = [
        ./ssh.nix
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