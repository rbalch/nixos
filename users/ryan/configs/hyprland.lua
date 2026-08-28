hl.monitor({ output = "DP-1", mode = "7680x2160@120", position = "0x0", scale = 1.25 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    -- No-op on Cortex, where Wayle owns awww. Other hosts still use Waybar.
    hl.exec_cmd("~/.config/hypr/start-wallpaper.sh")
    hl.exec_cmd("hyprctl setcursor GoogleDot-Blue 28")
    hl.exec_cmd("code", { workspace = "1 silent" })
    hl.exec_cmd("google-chrome-stable", { workspace = "1 silent" })
    hl.exec_cmd("handy") -- dictation daemon; toggle recording with Hyper+Space
    hl.exec_cmd("~/.config/hypr/start-blueman-applet.sh")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("~/.config/hypr/portal-resize.sh")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
end)

hl.env("XCURSOR_SIZE", "30")
hl.env("NIXOS_OZONE_WL", "1")

hl.config({
    xwayland = { force_zero_scaling = true },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        touchpad = { natural_scroll = true },
        sensitivity = 0,
    },
    general = {
        gaps_in = 5,
        gaps_out = 5,
        border_size = 1,
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        layout = "master",
    },
    master = {
        -- Center master once there are at least two stack windows.
        orientation = "center",
        new_status = "slave",
        mfact = 0.5,
    },
    decoration = { rounding = 10 },
    animations = { enabled = true },
})

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind(mainMod .. " + W", hl.dsp.window.close(), { description = "Close window" })
hl.bind(mainMod .. " + T", hl.dsp.window.float(), { description = "Toggle window floating" })
hl.bind("CTRL + ALT + E", hl.dsp.exec_cmd("nautilus"), { description = "Nautilus file manager" })
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("wofi --normal-window --show drun"), { description = "App launcher" })
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("~/.config/hypr/keybindings-menu.sh"), { description = "Show keybindings" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(), { description = "Toggle full screen" })
hl.bind(mainMod .. " + M", hl.dsp.layout("swapwithmaster"), { description = "Move window to master" })
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("ghostty"), { description = "Terminal" })
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_cmd("google-chrome-stable"), { description = "Browser" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("cosmic-files"), { description = "File manager" })

for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }), { description = "Focus window " .. direction })
    hl.bind(mainMod .. " + SHIFT + " .. direction, hl.dsp.window.swap({ direction = direction }), { description = "Swap window " .. direction })
end

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Switch to workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace " .. i })
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window with mouse" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window with mouse" })

hl.bind(mainMod .. " + ALT + right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true, description = "Grow window right" })
hl.bind(mainMod .. " + ALT + left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true, description = "Grow window left" })
hl.bind(mainMod .. " + ALT + up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true, description = "Grow window up" })
hl.bind(mainMod .. " + ALT + down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true, description = "Grow window down" })

local snapDirections = {
    left = "left", right = "right", up = "top", down = "bottom",
    Y = "tl", U = "tr", B = "bl", N = "br",
}
for key, region in pairs(snapDirections) do
    hl.bind("CTRL + ALT + SHIFT + " .. key, hl.dsp.exec_cmd("~/.config/hypr/snap.sh " .. region), { description = "Snap window " .. region })
end

hl.bind("CTRL + ALT + SHIFT + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]), { description = "Copy region screenshot" })
-- Ctrl+Alt+Space works on standard keyboards; keep Hyper+Space for the Moonlander.
-- Keep both a standard-keyboard chord and Hyper+Space for the Moonlander.
hl.bind("CTRL + ALT + SPACE", hl.dsp.exec_cmd("handy --toggle-transcription"), { description = "Toggle dictation" })
hl.bind("SUPER + CTRL + ALT + SHIFT + SPACE", hl.dsp.exec_cmd("handy --toggle-transcription"), { description = "Toggle dictation" })
-- Hyper+H: Handy transcription with LLM post-processing.
hl.bind("SUPER + CTRL + ALT + SHIFT + H", hl.dsp.exec_cmd("handy --toggle-post-process"), { description = "Toggle processed dictation" })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, description = "Raise volume" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, description = "Lower volume" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { description = "Mute audio" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true, description = "Lower brightness" })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true, description = "Raise brightness" })

hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock screen" })
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock screen" })
hl.bind("SUPER + ESCAPE", hl.dsp.exec_cmd("~/.config/hypr/power-menu.sh"), { description = "Power menu" })

hl.window_rule({
    name = "chrome-suppress-maximize",
    match = { class = "^(google-chrome)$" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "float-gtk-portal-dialogs",
    match = { class = "^(xdg-desktop-portal-gtk)$" },
    float = true,
})
