{ lib, hostName, ... }:

{
  # Trial Wayle on Cortex first. The other hosts keep Waybar until this setup
  # has had time in a live Hyprland session.
  services.wayle = lib.mkIf (hostName == "cortex") {
    enable = true;
    autoInstallDependencies = true;

    settings = {
      bar = {
        location = "top";
        scale = 1.0;
        background-opacity = 0;
        button-variant = "basic";
        button-bg-opacity = 0;
        button-border-location = "none";
        button-group-background = "#000000b3";
        button-group-padding = 0.25;
        button-group-rounding = "sm";
        dropdown-autohide = true;

        layout = [{
          monitor = "DP-1";
          left = [
            "dashboard"
            "hyprland-workspaces"
            "window-title"
          ];
          center = [{
            name = "center-status";
            modules = [
              "clock"
              "media"
            ];
          }];
          right = [
            "systray"
            "cpu"
            "ram"
            "microphone"
            "volume"
            "network"
            "bluetooth"
            "notifications"
          ];
        }];
      };

      modules = {
        clock.format = "%Y-%m-%d  %H:%M - %a";
        notifications.popup-monitor = "DP-1";
      };

      osd.monitor = "DP-1";

      wallpaper = {
        engine-enabled = true;
        transition-type = "simple";
        transition-duration = 0.7;
        transition-fps = 60;
        cycling-enabled = false;
        monitors = [{
          name = "DP-1";
          wallpaper = "/home/ryan/Pictures/backgrounds/earth.jpg";
          fit-mode = "fill";
        }];
      };
    };
  };
}
