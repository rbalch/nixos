#!/usr/bin/env bash
# Power menu via wofi. Bound to SUPER+SHIFT+BACKSPACE in hyprland.conf.

choice=$(printf "Lock\nScreen Off\nSuspend\nLogout\nReboot\nShutdown" \
  | wofi --dmenu --prompt "Power" --width 280 --height 280)

case "$choice" in
  Lock)         loginctl lock-session ;;
  "Screen Off") loginctl lock-session && sleep 0.5 && hyprctl dispatch 'hl.dsp.dpms({ action = "off" })' ;;
  Suspend)      loginctl lock-session && sleep 0.5 && systemctl suspend ;;
  Logout|Reboot|Shutdown)
    # Keep a named copy from before windows close. The daemon's automatic
    # 'last' save can catch only part of the logout sequence.
    hypr-persist save before-exit || true
    case "$choice" in
      Logout)   hyprctl dispatch exit ;;
      Reboot)   systemctl reboot ;;
      Shutdown) systemctl poweroff ;;
    esac
    ;;
esac
