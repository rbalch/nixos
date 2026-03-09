{ config, pkgs, inputs, ... }:

{

    environment.systemPackages = with pkgs; [
        brightnessctl
        pavucontrol
        wayland-logout
        wl-clipboard
        inputs.sddm-stray.packages.${pkgs.system}.default
    ];

    programs.hyprland = {
        enable = true;
        xwayland.enable = true;
    };

    services.xserver = {
        enable = true;
        xkb.layout = "us";
    };

    services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        theme = "sddm-stray";
        extraPackages = [ pkgs.kdePackages.qtmultimedia pkgs.kdePackages.qtsvg pkgs.kdePackages.qtvirtualkeyboard ];
    };

    xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
}
