{ config, pkgs, ... }:

{

    environment.systemPackages = with pkgs; [
        brightnessctl
        pavucontrol
        wayland-logout
        wl-clipboard
        (sddm-astronaut.override {
            embeddedTheme = "pixel_sakura_static";
        })
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
        theme = "sddm-astronaut-theme";
        extraPackages = [ pkgs.kdePackages.qtmultimedia pkgs.kdePackages.qtsvg pkgs.kdePackages.qtvirtualkeyboard ];
    };

    xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
}
