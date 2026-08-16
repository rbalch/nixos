hl.monitor({ output = "DP-1", mode = "7680x2160@120", position = "0x0", scale = 1.25 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1 && awww img /home/ryan/Pictures/backgrounds/earth.jpg")
    hl.exec_cmd("hyprctl setcursor GoogleDot-Blue 28")
    -- xremap loses Hyprland IPC if it starts before the socket exists at login.
    hl.exec_cmd("systemctl --user restart xremap.service")
    hl.exec_cmd("code", { workspace = "1 silent" })
    hl.exec_cmd("google-chrome-stable", { workspace = "1 silent" })
    hl.exec_cmd("handy") -- dictation daemon; toggle recording with Hyper+Space
    hl.exec_cmd("blueman-applet")
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

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("~/.config/hypr/super-t.sh"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("cosmic-files"))
hl.bind("CTRL + ALT + E", hl.dsp.exec_cmd("nautilus"))
hl.bind("CTRL + ALT + F", hl.dsp.window.float())
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("wofi --normal-window --show drun"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + RETURN", hl.dsp.layout("swapwithmaster"))
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.layout("focusmaster"))

for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
    hl.bind(mainMod .. " + SHIFT + " .. direction, hl.dsp.window.swap({ direction = direction }))
end

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + ALT + right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })

local snapDirections = {
    left = "left", right = "right", up = "top", down = "bottom",
    Y = "tl", U = "tr", B = "bl", N = "br",
}
for key, region in pairs(snapDirections) do
    hl.bind("CTRL + ALT + SHIFT + " .. key, hl.dsp.exec_cmd("~/.config/hypr/snap.sh " .. region))
end

hl.bind("CTRL + ALT + SHIFT + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))
hl.bind("SUPER + CTRL + ALT + SHIFT + SPACE", hl.dsp.exec_cmd("handy --toggle-transcription"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true })

hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("SUPER + BACKSPACE", hl.dsp.exec_cmd("~/.config/hypr/power-menu.sh"))

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
