{ config, pkgs, lib, ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

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
        background: transparent;
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