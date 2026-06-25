#!/usr/bin/env bash
# SUPER+T: new tab if Ghostty is focused, otherwise launch a new Ghostty window.
# Bypasses the Wayland reality that Hyprland-level binds eat the key before
# the app sees it.

read -r class addr < <(hyprctl activewindow -j | jq -r '"\(.class) \(.address)"')

if [[ "$class" == "com.mitchellh.ghostty" ]]; then
  hyprctl dispatch sendshortcut "CTRL ALT, T, address:$addr"
else
  ghostty
fi
