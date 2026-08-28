#!/usr/bin/env bash

# Show the named binds from the running Hyprland session.
hyprctl binds | awk '
function modifier_text(mask) {
  if (mask == 0) return ""
  if (mask == 1) return "SHIFT"
  if (mask == 4) return "CTRL"
  if (mask == 5) return "CTRL + SHIFT"
  if (mask == 8) return "ALT"
  if (mask == 9) return "ALT + SHIFT"
  if (mask == 12) return "CTRL + ALT"
  if (mask == 13) return "CTRL + ALT + SHIFT"
  if (mask == 64) return "SUPER"
  if (mask == 65) return "SUPER + SHIFT"
  if (mask == 68) return "SUPER + CTRL"
  if (mask == 69) return "SUPER + CTRL + SHIFT"
  if (mask == 72) return "SUPER + ALT"
  if (mask == 73) return "SUPER + ALT + SHIFT"
  if (mask == 76) return "SUPER + CTRL + ALT"
  if (mask == 77) return "SUPER + CTRL + ALT + SHIFT"
  return mask
}

function emit(    mods, combo) {
  if (!seen || description == "" || key == "") return
  sub(/^.* \+ /, "", key)
  mods = modifier_text(modmask)
  combo = (mods == "" ? key : mods " + " key)
  printf "%-38s  %s\n", combo, description
}

/^bind/ {
  emit()
  seen = 1
  modmask = 0
  key = ""
  description = ""
  next
}

seen && /^\tmodmask: / { modmask = substr($0, 11); next }
seen && /^\tkey: / { key = substr($0, 7); next }
seen && /^\tdescription: / { description = substr($0, 15); next }
END { emit() }
' | sort -f | wofi --dmenu --prompt "Keybindings" --width 900 --height 650 --insensitive >/dev/null
