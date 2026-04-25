{ config, pkgs, lib, ... }:

{
    environment.systemPackages = with pkgs; [
        brightnessctl
        pavucontrol
        uwsm
        wayland-logout
        wl-clipboard
    ];

    programs.hyprland = {
        enable = true;
        xwayland.enable = true;
        withUWSM = true;
    };

    # Link uwsm's user systemd units into /etc/systemd/user/ so
    # wayland-session-bindpid@.service and friends are found at login
    environment.etc = lib.mapAttrs'
      (name: _: {
        name = "systemd/user/${name}";
        value.source = "${pkgs.uwsm}/share/systemd/user/${name}";
      })
      (lib.filterAttrs (_: t: t == "regular")
        (builtins.readDir "${pkgs.uwsm}/share/systemd/user"));

    services.xserver = {
        enable = true;
        xkb.layout = "us";
    };

    services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        extraPackages = [ pkgs.kdePackages.qtmultimedia pkgs.kdePackages.qtsvg pkgs.kdePackages.qtvirtualkeyboard ];
    };

    xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
}
