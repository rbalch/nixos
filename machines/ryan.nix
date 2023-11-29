{ config, pkgs, ... }:

{
    programs.zsh.enable = true;

    users.users.ryan = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
    };

    # fonts.packages = with pkgs; [
    #     (nerdfonts.override { fonts = [ "Meslo" ]; })
    # ];

}