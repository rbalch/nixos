#!/usr/bin/env bash
# Force xdg-desktop-portal-gtk file dialogs to a sane size + centered.
# The GTK file chooser overrides any `size` windowrule with its own configure
# after map, so we react to the openwindow IPC event instead.

set -u

SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
CLASS="xdg-desktop-portal-gtk"
W=1200
H=800

nc -U "$SOCK" | while IFS= read -r line; do
    case "$line" in
        openwindow\>\>*,"$CLASS",*)
            # Let the GTK widget finish its own resize before we clobber it.
            sleep 0.15
            hyprctl dispatch resizewindowpixel "exact $W $H,class:^(${CLASS})\$" >/dev/null
            hyprctl dispatch centerwindow >/dev/null
            ;;
    esac
done
