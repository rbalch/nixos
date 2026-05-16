{ config, pkgs, lib, hostName, ... }:

let
  modulesRight =
    [ "cpu" "memory" ]
    ++ lib.optional (hostName == "nix1") "battery"
    ++ [ "backlight" "wireplumber" "network" ];
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = [{
      layer = "top";
      position = "top";
      "modules-left" = [ "hyprland/workspaces" "hyprland/window" ];
      "modules-center" = [ "clock" ];
      "modules-right" = modulesRight;

      backlight = {
        device = "intel_backlight";
        format = "{percent}% {icon}";
        "format-icons" = [ "" "" ];
      };

      battery = {
        format = "{capacity}% {icon}";
        "format-icons" = [ "" "" "" "" "" ];
      };

      clock = {
        interval = 60;
        format = "{:%Y-%m-%d  %H:%M - %a}";
        "format-alt" = "{:%A, %B %d, %Y (%R)}";
        "tooltip-format" = "<tt><small>{calendar}</small></tt>";
        calendar = {
          mode = "year";
          "mode-mon-col" = 3;
          format = {
            months = "<span color='#ffead3'><b>{}</b></span>";
            days = "<span color='#ecc6d9'><b>{}</b></span>";
            weeks = "<span color='#99ffdd'><b>W{}</b></span>";
            weekdays = "<span color='#ffcc66'><b>{}</b></span>";
            today = "<span color='#ff6699'><b>{}</b></span>";
          };
        };
      };

      cpu = {
        format = "{usage}% 󰫕";
      };

      "hyprland/workspaces" = {
        format = "{name}";
        "on-click" = "activate";
        "sort-by-number" = true;
      };

      memory = {
        format = "{}% 󰑹";
      };

      network = {
        "format-wifi" = "{signalStrength}% {icon}";
        "format-ethernet" = "{ifname}: {ipaddr}/{cidr} ethernet";
        "format-disconnected" = "⚠";
        "format-icons" = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
      };

      wireplumber = {
        format = "{volume}% {icon}";
        "format-muted" = "󰖁";
        "format-icons" = [ "" "" "" ];
      };
    }];

    style = ''
      ${builtins.readFile "${pkgs.waybar}/etc/xdg/waybar/style.css"}

      #backlight {
        background: transparent;
        color: white;
      }

      #battery {
        color: white;
        background: transparent;
      }

      #clock {
        background: rgba(0, 0, 0, 0.7);
        border-radius: 10px;
        padding: 0 14px;
      }

      #cpu {
        color: white;
        background: transparent;
      }

      #memory {
        background: transparent;
      }

      #network {
        background: transparent;
      }

      #wireplumber {
        background: transparent;
        color: white;
      }

      window#waybar {
        background: transparent;
        border-bottom: none;
      }

      #workspaces button.active {
        color: #ffa700;
      }

      #workspaces button.focused {
        background: #4c566a;
        border-bottom: 3px solid #e5e9f0;
      }
    '';
  };
}
