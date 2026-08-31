{ config, inputs, lib, pkgs, hostName, ... }:

let
    claude-desktop = import ../../packages/claude-desktop {
        inherit pkgs;
        packageIndex = inputs.claude-desktop-repo;
    };

    # Codex calls this after a turn. BEL lets the active terminal choose how
    # to alert instead of tying Codex to a desktop sound player.
    codex-notify = pkgs.writeShellScript "codex-notify" ''
        printf '\a' > /dev/tty
    '';
in {
    home.username = "ryan";
    home.homeDirectory = "/home/ryan";
    home.stateVersion = "25.11";

    imports = [
        ./nvim.nix
        ./ssh.nix
        ./vscode.nix
        ./waybar.nix
        ./wayle.nix
        ./zsh.nix
    ];

    # Keep one systemd-owned Hypridle process. The settings stay in the raw
    # config file below so its Hyprland Lua dispatch calls remain unchanged.
    services.hypridle.enable = true;
    systemd.user.services.hypridle.Unit.X-Restart-Triggers = [
        "${./configs/hypr/hypridle.conf}"
    ];

    # Native claude install lives in ~/.local/bin; ensure it's on PATH and beats
    # any stale wrappers from /etc/profiles.
    home.sessionPath = [ "$HOME/.local/bin" ];

    # Bootstrap claude-code into ~/.local/bin on first rebuild (or any rebuild
    # where the binary is missing). Subsequent rebuilds are silent no-ops.
    # Claude's own self-updater handles all upgrades after this.
    home.activation.claudeCodeBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -x "$HOME/.local/bin/claude" ]; then
            run ${pkgs.nodejs_24}/bin/npx --yes \
                @anthropic-ai/claude-code@latest install latest
        fi
    '';

    # Bootstrap pi into ~/.local on first rebuild. `pi update` handles later
    # upgrades while keeping the install outside the read-only Nix store.
    home.activation.piBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -x "$HOME/.local/bin/pi" ]; then
            run ${pkgs.nodejs_24}/bin/node \
                ${pkgs.nodejs_24}/lib/node_modules/npm/bin/npm-cli.js \
                install -g --prefix "$HOME/.local" --ignore-scripts \
                @earendil-works/pi-coding-agent
        fi
    '';

    # Bootstrap the official Grok Build client into ~/.local/bin on first
    # rebuild. `grok update` handles later upgrades. Hide the managed shell
    # from the installer so it does not try to edit Home Manager's .zshrc.
    home.activation.grokBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -x "$HOME/.local/bin/grok" ]; then
            installer="$(${pkgs.coreutils}/bin/mktemp)"
            run ${pkgs.curl}/bin/curl -fsSL \
                https://x.ai/cli/install.sh \
                -o "$installer"
            run ${pkgs.coreutils}/bin/env \
                SHELL=/bin/false \
                GROK_BIN_DIR="$HOME/.local/bin" \
                PATH=${lib.makeBinPath [ pkgs.bash pkgs.coreutils pkgs.curl pkgs.gawk pkgs.gnugrep pkgs.gnused ]} \
                ${pkgs.bash}/bin/bash "$installer"
            rm -f "$installer"
        fi
    '';

    home.packages = with pkgs; [
        awscli2
        cliamp
        pulseaudio # pactl: inspect and switch PipeWire/PulseAudio outputs
        code-cursor
        fd
        font-manager
        google-chrome
		google-cloud-sdk
        google-cursor
        hyprlock
        nwg-look
        nodejs_24
        pay-respects
        ripgrep
        slack
		terraform
        nautilus
        cosmic-files
        udiskie
        wofi
        obsidian
        warp-terminal
        waveterm
        sshfs
        vlc
        grim
        slurp
        wl-clipboard
        gh
    ]
    # Wayle owns awww on Cortex. Keep the direct package for hosts that still
    # use the Waybar + Hyprland startup path.
    ++ lib.optionals (hostName != "cortex") [
        pkgs.awww
    ]
        # Handy: offline speech-to-text (Whisper/Parakeet), Wispr-Flow-style dictation.
        # Its GPU accel is Vulkan (works on NVIDIA w/o CUDA), but it links onnxruntime,
        # which the global `nixpkgs.config.cudaSupport = true` would otherwise rebuild
        # with the CUDA EP from source (huge, OOM-prone). Force it to CPU — Whisper
        # still runs on GPU via Vulkan, Parakeet is CPU-optimized anyway.
        # Scoped off brain-dongle: headless GPU server, never dictated to — skips its
        # ~1.4GB webkit+onnxruntime closure (and the from-source onnx build) there.
    ++ lib.optionals (hostName != "brain-dongle") [
        ((handy.override { onnxruntime = onnxruntime.override { cudaSupport = false; }; }).overrideAttrs (old: {
            # Handy 0.9.1 sends reasoning_effort=none to every custom endpoint,
            # but the DGX vLLM gpt-oss server accepts only low, medium, or high.
            patches = (old.patches or [ ]) ++ [ ./patches/handy-vllm-reasoning-effort.patch ];
        }))
        wtype       # Wayland "type" tool — Handy's injection backend on wlroots
        pkgs.v4l-utils
        zed-editor
    ]
    # Official Linux .deb, wrapped for NixOS with Wayland and GNOME Keyring.
    # hostName is nix1 even though that host's config directory is x1.
    ++ lib.optionals (lib.elem hostName [ "cortex" "nix1" ]) [
        claude-desktop
    ]
    ++ [
        (pkgs.writeShellScriptBin "docker-stop" ''
            #!/bin/bash
            docker stop $(docker ps -q)
        '')

        # AI CLIs via npx — invoking via full nodejs to bypass nixpkgs bug
        # where npx's shebang points to nodejs-slim (missing /lib), causing
        # npm's globalDir lookup to crash with ENOENT on /lib.
        (pkgs.writeShellScriptBin "codex" ''
          #!/usr/bin/env bash
          exec ${pkgs.nodejs_24}/bin/node \
            ${pkgs.nodejs_24}/lib/node_modules/npm/bin/npx-cli.js \
            @openai/codex@latest \
            --config 'notify=["${codex-notify}"]' \
            "$@"
        '')

        (pkgs.writeShellScriptBin "gemini" ''
          #!/usr/bin/env bash
          exec ${pkgs.nodejs_24}/bin/node ${pkgs.nodejs_24}/lib/node_modules/npm/bin/npx-cli.js @google/gemini-cli@latest "$@"
        '')

        (pkgs.writeShellScriptBin "copy-to-bd-movie" ''
          #!/usr/bin/env bash
          set -euo pipefail

          src="''${1:?usage: copy-to-bd-movie <file>}"

          host="bd"
          dest_dir="~/other/movies"
          dest_path="''${dest_dir}/$(basename "$src")"

          ssh -o BatchMode=yes "$host" "mkdir -p $dest_dir" >/dev/null 2>&1 || {
            echo "Failed to reach $host or create $dest_dir"
            exit 1
          }

          rsync -a --partial --append-verify --info=progress2 \
            "$src" "''${host}:''${dest_path}"
        '')
    ] ++ lib.optionals (hostName == "cortex") [
        # orca-slicer on the native Wayland backend. Forcing GDK_BACKEND=x11 was a
        # 2.3.x workaround for a blank wxGLCanvas, but 2.4.2 ships wxWidgets 3.3.2
        # (wxGLCanvasEGL), and on XWayland the forced GLX path makes NVIDIA raise an
        # X error inside MakeCurrent whenever the GL context is re-made after a
        # background job finishes — slice-complete and send-to-printer both abort,
        # since GDK escalates unhandled X errors to a fatal g_error.
        # symlinkJoin avoids re-triggering the (very long) orca-slicer compile.
        # Cortex-only: the other hosts are headless (brain-dongle) or GPU-less.
        (pkgs.symlinkJoin {
            name = "orca-slicer-${pkgs.orca-slicer.version}";
            paths = [ pkgs.orca-slicer ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
                wrapProgram $out/bin/orca-slicer \
                    --set-default __GL_THREADED_OPTIMIZATIONS 0
            '';
        })
    ];

    home.file = {
        # Hyprland 0.56 prefers Lua at startup. Keep the legacy file during the
        # move so sessions that started with the old parser can still reload.
        ".config/hypr/hyprland.lua".source = configs/hyprland.lua;
        ".config/hypr/hyprland.conf".source = configs/hyprland.conf;
        ".config/nixpkgs/config.nix".source = configs/config.nix;
        ".pi/agent/models.json".source = configs/pi/models.json;
        ".pi/agent/extensions/italic-yellow.ts".source = configs/pi/extensions/italic-yellow.ts;
        "Pictures/backgrounds/earth.jpg".source = backgrounds/earth.jpg;
        ".config/hypr/hypridle.conf".source = configs/hypr/hypridle.conf;
        ".config/hypr/hyprlock.conf".source = configs/hypr/hyprlock.conf;
        ".config/hypr/snap.sh" = { source = configs/hypr/snap.sh; executable = true; };
        ".config/hypr/power-menu.sh" = { source = configs/hypr/power-menu.sh; executable = true; };
        ".config/hypr/keybindings-menu.sh" = { source = configs/hypr/keybindings-menu.sh; executable = true; };
        ".config/hypr/portal-resize.sh" = { source = configs/hypr/portal-resize.sh; executable = true; };
        # Cortex lets Wayle own awww. Other hosts still start the same static
        # wallpaper from Hyprland until they move from Waybar.
        ".config/hypr/start-wallpaper.sh" = {
            executable = true;
            text = if hostName == "cortex" then ''
                #!/bin/sh
                exit 0
            '' else ''
                #!/bin/sh
                ${pkgs.awww}/bin/awww-daemon &
                sleep 1
                exec ${pkgs.awww}/bin/awww img /home/ryan/Pictures/backgrounds/earth.jpg
            '';
        };
        # Wayle has its own Bluetooth control on Cortex. Keep Blueman's tray
        # applet for the hosts that still use Waybar.
        ".config/hypr/start-blueman-applet.sh" = {
            executable = true;
            text = if hostName == "cortex" then ''
                #!/bin/sh
                exit 0
            '' else ''
                #!/bin/sh
                exec blueman-applet
            '';
        };
        ".config/Cursor/User/keybindings.json".source = configs/cursor/keybindings.json;
        ".config/zed/keymap.json".source = configs/zed/keymap.json;
        # Chrome opens the screencast portal TWICE per share: once for its own
        # source picker, then again for the real stream. Without a restore token
        # the second request logs "restore data invalid / missing, prompting" and
        # re-opens the xdph picker, so you must reselect the source mid-share.
        # Granting tokens by default lets the second request restore silently.
        ".config/hypr/xdph.conf".text = ''
            screencopy {
                allow_token_by_default = true
            }
        '';
        ".config/tmux/tmux.conf".source = configs/tmux.conf;
        # Chrome's Auto Dark Mode has no user-facing per-site exception list.
        # This unpacked, CSS-only extension opts Google Docs/Slides out before
        # their page is rendered; load it once from chrome://extensions.
        ".config/chrome-extensions/google-docs-light".source = configs/chrome-extensions/google-docs-light;
        ".local/share/applications/figma-linux.desktop".text = ''
            [Desktop Entry]
            Name=Figma Linux
            Exec=env NIXOS_OZONE_WL="" GTK_THEME=Adwaita:dark figma-linux --ozone-platform=x11 --force-dark-mode %U
            Icon=figma-linux
            Comment=Unofficial Figma desktop application for Linux
            Terminal=false
            Type=Application
            MimeType=x-scheme-handler/figma;
        '';
        # vscode wayland font fix
        ".config/code-flags.conf".text = "--ozone-platform=wayland";
        # chrome wayland stability — prevent crash on DPMS off / suspend
        # --disable-gpu-compositing disabled: it tanks Netflix to 540p. Re-add if DPMS crashes return.
        ".config/chrome-flags.conf".text = ''
            --ozone-platform=wayland
            --enable-features=UseOzonePlatform
            --disable-features=WaylandWpColorManagerV1
        '';
    };

    home.pointerCursor = {
        enable = true;
        gtk.enable = true;
        package = pkgs.google-cursor;
        name = "GoogleDot-Blue";
        size = 28;
    };


    xdg.mimeApps = {
        enable = true;
        defaultApplications = {
            "inode/directory" = "com.system76.CosmicFiles.desktop";
            "application/x-gnome-saved-search" = "com.system76.CosmicFiles.desktop";
            "text/html" = "google-chrome.desktop";
            "x-scheme-handler/http" = "google-chrome.desktop";
            "x-scheme-handler/https" = "google-chrome.desktop";
            "x-scheme-handler/about" = "google-chrome.desktop";
            "x-scheme-handler/unknown" = "google-chrome.desktop";
            "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
            "x-scheme-handler/claude" = "claude.desktop";
            "x-scheme-handler/slack" = "slack.desktop";
            "x-scheme-handler/figma" = "figma-linux.desktop";
        };
    };

    programs.git = {
        enable = true;
        lfs.enable = true;
        settings = {
            user.email = "ryan@balch.io";
            user.name = "Ryan Balch";
            core.editor = "vim";
        };
    };

    programs.password-store = {
        enable = true;
        settings = {
        PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
        };
    };

    programs.ghostty = {
    enable = true;
    settings = {
        font-family = "MesloLGS Nerd Font";
        font-size = 14;
        theme = "TokyoNight";
        background-opacity = 0.95;
        background-blur = true;
        window-width = 160;
        window-height = 70;
        # Codex sends BEL with its turn notice, so Ghostty plays this sound
        # beside the desktop popup.
        bell-features = "audio";
        bell-audio-path = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";
        bell-audio-volume = 0.4;
        # Super+C/V are free in Hyprland and avoid the longer terminal
        # clipboard chords. Ctrl+C remains SIGINT/cancel.
        keybind = [
        "super+c=copy_to_clipboard"
        "super+v=paste_from_clipboard"
        "ctrl+alt+t=new_tab"
        ];
    };
    };

}
