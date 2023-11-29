{ config, pkgs, lib, users, ... }:

{
    users.users.ryan = {
        isNormalUser = true;
        extraGroups = [ "wheel" "docker" ];
        shell = pkgs.zsh;
    };
    home.username = "ryan";
    home.homeDirectory = lib.mkForce "/home/ryan";
    home.stateVersion = "23.05";

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