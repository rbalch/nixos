{ config, pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        dig
        git
        fzf
        jq
        networkmanager
        thefuck
    ];
}