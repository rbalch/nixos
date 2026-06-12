#!/usr/bin/env bash
# Snap active window to a region of the focused monitor.
# Usage: snap.sh {left|right|top|bottom|tl|tr|bl|br}

REGION="$1"
ADDR=$(hyprctl activewindow -j | jq -r '.address')
MON=$(hyprctl monitors -j | jq '.[] | select(.focused==true)')
MW=$(echo "$MON" | jq '.width')
MH=$(echo "$MON" | jq '.height')
MX=$(echo "$MON" | jq '.x')
MY=$(echo "$MON" | jq '.y')
SCALE=$(echo "$MON" | jq '.scale')

LW=$(awk -v w=$MW -v s=$SCALE 'BEGIN{printf "%d", w/s}')
LH=$(awk -v h=$MH -v s=$SCALE 'BEGIN{printf "%d", h/s}')
HW=$((LW/2))
HH=$((LH/2))

case "$REGION" in
    left)   X=$MX;          Y=$MY;          W=$HW; H=$LH ;;
    right)  X=$((MX + HW)); Y=$MY;          W=$HW; H=$LH ;;
    top)    X=$MX;          Y=$MY;          W=$LW; H=$HH ;;
    bottom) X=$MX;          Y=$((MY + HH)); W=$LW; H=$HH ;;
    tl)     X=$MX;          Y=$MY;          W=$HW; H=$HH ;;
    tr)     X=$((MX + HW)); Y=$MY;          W=$HW; H=$HH ;;
    bl)     X=$MX;          Y=$((MY + HH)); W=$HW; H=$HH ;;
    br)     X=$((MX + HW)); Y=$((MY + HH)); W=$HW; H=$HH ;;
    *)      echo "usage: $0 {left|right|top|bottom|tl|tr|bl|br}" >&2; exit 1 ;;
esac

hyprctl --batch "\
  dispatch setfloating address:$ADDR; \
  dispatch resizewindowpixel exact $W $H,address:$ADDR; \
  dispatch movewindowpixel exact $X $Y,address:$ADDR"
