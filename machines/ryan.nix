{ config, pkgs, ... }:

{
    users.users.ryan = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
    };
}