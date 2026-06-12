#!/usr/bin/env bash
# SUPER+T: new tab if Ghostty is focused, otherwise launch a new Ghostty window.
# Bypasses the Wayland reality that Hyprland-level binds eat the key before
# the app sees it.

class=$(hyprctl activewindow -j | jq -r .class)

if [[ "$class" == "com.mitchellh.ghostty" ]]; then
  hyprctl dispatch sendshortcut "CTRL ALT, T, class:^(com\.mitchellh\.ghostty)$"
else
  ghostty
fi
