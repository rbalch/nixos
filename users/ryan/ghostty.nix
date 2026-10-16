{ lib, pkgs, ... }:

let
    isDarwin = pkgs.stdenv.isDarwin;
in {
    programs.ghostty = {
        enable = true;
        # nixpkgs' `ghostty` is Linux-only; `ghostty-bin` is the official
        # signed macOS app.
        package = lib.mkIf isDarwin pkgs.ghostty-bin;
        settings = {
            font-family = "MesloLGS Nerd Font";
            font-size = 14;
            theme = "TokyoNight";
            background-opacity = 0.95;
            background-blur = true;
            window-width = 160;
            window-height = 70;
        } // lib.optionalAttrs (!isDarwin) {
            # Codex sends BEL with its turn notice, so Ghostty plays this sound
            # beside the desktop popup. macOS keeps its own bell behavior.
            bell-features = "audio";
            bell-audio-path = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";
            bell-audio-volume = 0.4;
            # Super+C/V are free in Hyprland and avoid the longer terminal
            # clipboard chords. Ctrl+C remains SIGINT/cancel. macOS Ghostty
            # already binds Cmd+C/V and Cmd+T.
            keybind = [
                "super+c=copy_to_clipboard"
                "super+v=paste_from_clipboard"
                "ctrl+alt+t=new_tab"
            ];
        };
    };
}
