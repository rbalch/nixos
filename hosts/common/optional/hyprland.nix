{ config, pkgs, lib, inputs, ... }:

let
    hyprlandPackages = inputs.hyprland-pinned.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    patchedPortal = hyprlandPackages.xdg-desktop-portal-hyprland.overrideAttrs (old: {
        # XDPH 1.4.1 can destroy a new frame callback while PipeWire changes
        # formats, which freezes or kills window sharing. These fixes landed
        # upstream after 1.4.1. Keep them local while Hyprland stays pinned for
        # the Cortex NVIDIA DPMS wake fix noted in TODO.md.
        patches = (old.patches or [ ]) ++ [
            ./patches/xdph-out-of-buffers.patch
            ./patches/xdph-format-renegotiation.patch
        ];
    });
in

{
    imports = [ ./xremap.nix ];

    environment.systemPackages = with pkgs; [
        brightnessctl
        pavucontrol
        uwsm
        wayland-logout
        wl-clipboard
        (sddm-astronaut.override { embeddedTheme = "black_hole"; })
    ];

    programs.hyprland = {
        enable = true;
        package = hyprlandPackages.hyprland;
        portalPackage = patchedPortal;
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
        theme = "sddm-astronaut-theme";
        package = pkgs.kdePackages.sddm;
        extraPackages = [
            pkgs.kdePackages.qtmultimedia
            pkgs.kdePackages.qtsvg
            pkgs.kdePackages.qtvirtualkeyboard
            pkgs.kdePackages.qt5compat
        ];
    };

    xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
}
