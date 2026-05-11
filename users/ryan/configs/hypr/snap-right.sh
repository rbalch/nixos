#!/usr/bin/env bash
# Snap active window to right half of the focused monitor

ADDR=$(hyprctl activewindow -j | jq -r '.address')
MON=$(hyprctl monitors -j | jq '.[] | select(.focused==true)')
W=$(echo "$MON" | jq '.width')
H=$(echo "$MON" | jq '.height')
SCALE=$(echo "$MON" | jq '.scale')

LW=$(echo "$W $SCALE" | awk '{printf "%d", $1/$2}')
LH=$(echo "$H $SCALE" | awk '{printf "%d", $1/$2}')

hyprctl dispatch setfloating address:$ADDR
hyprctl dispatch movewindowpixel exact $((LW/2)) 0,address:$ADDR
hyprctl dispatch resizewindowpixel exact $((LW/2)) $LH,address:$ADDR
