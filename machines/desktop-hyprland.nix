{ config, pkgs, ... }:

{
    programs.hyprland = {
        enable = true;
        xwayland.enable = true;
    };

    services.xserver = {
        enable = true;
        layout = "us";
        displayManager.sddm.enable = true;
    };

    xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
}