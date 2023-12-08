{ config, pkgs, ... }:

{

    environment.systemPackages = with pkgs; [
        brightnessctl
        hyprpaper
        pavucontrol
        wl-clipboard
    ];

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