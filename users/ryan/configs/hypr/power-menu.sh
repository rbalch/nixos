#!/usr/bin/env bash
# Power menu via wofi. Bound to SUPER+SHIFT+BACKSPACE in hyprland.conf.

choice=$(printf "Lock\nScreen Off\nSuspend\nLogout\nReboot\nShutdown" \
  | wofi --dmenu --prompt "Power" --width 280 --height 280)

case "$choice" in
  Lock)         loginctl lock-session ;;
  "Screen Off") loginctl lock-session && sleep 0.5 && hyprctl dispatch dpms off ;;
  Suspend)      loginctl lock-session && sleep 0.5 && systemctl suspend ;;
  Logout)       hyprctl dispatch exit ;;
  Reboot)       systemctl reboot ;;
  Shutdown)     systemctl poweroff ;;
esac
