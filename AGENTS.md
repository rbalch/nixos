# Repository guidance

## Scope and layout

This flake manages five NixOS hosts for one user, `ryan`, using `nixpkgs-unstable` and Home Manager as a NixOS module.

- `flake.nix` defines inputs and hosts. Inputs include nixpkgs, Home Manager, Hyprland, nixos-hardware, vscode-server, xremap, Tether, and the Claude Desktop apt index.
- `lib/mkHost.nix` wires `hosts/<dir>` to `users/ryan`. Its interface is `mkHost hostname { system?, dir?, modules?, homeModule? }`; defaults are `x86_64-linux`, the host name, no extra modules, and `users/ryan` for Home Manager.
- `mkHost` passes `inputs` and `hostName` to both NixOS and Home Manager. Home Manager uses system packages (`useGlobalPkgs = true`), `useUserPackages = true`, and the backup suffix `hm-backup`.
- `hosts/common/base.nix` holds boot-free settings for every host; `hosts/common/default.nix` adds native-only settings on top; `hosts/common/optional/` holds modules that hosts choose to import.
- `users/ryan/default.nix` holds desktop apps, file mappings, and personal identity. `cli.nix` holds shared CLI tools, shared dotfiles, and install hooks. Other user modules hold editor, shell, SSH, and bar settings.
- `machines/balch-huge/` is a separate nix-darwin flake. Leave it alone unless the task concerns the Mac.
- Root `configuration.nix` is outside this flake. `make get-config` downloads that file for recovery; don't edit it unless the task concerns that path.

Check the code before relying on a package list or old workaround. Keep this guide focused on rules and reasons; keep pending checks in `TODO.md`.

## Commands

```bash
make rebuild              # switch the current host, selected by hostname
make rebuild-cortex       # switch cortex with --max-jobs 4 --cores 6
make rebuild-braindongle  # switch brain-dongle with the same limits
make rebuild-nix1         # switch nix1 explicitly
make update               # update all flake inputs
make check-build          # one dry-build; show Nix's build/download plan and errors
make diff                 # build without switching, then compare with the running system
make update-diff          # update inputs, then run make diff
make cleanup              # remove system generations older than 7 days, then collect garbage
make garbage              # nix-collect-garbage --delete-old
make test-docker           # run the configured NVIDIA container check
make check-docker         # show Docker runtimes
make fix-vscode           # restart the vscode-server patch service on brain-dongle
make restart-idle         # restart the user's hypridle service
```

Rebuild targets, `diff`, and `check-build` run `git add -AN .` so flakes see new files. Preserve that step. The generic rebuild works on nix1: it selects the flake output, not the host directory.

Fresh install: `nixos-install --no-write-lock-file --impure --flake github:rbalch/nixos#<host>`. `make install` selects razor.

## Hosts

| Host | Directory | Current setup |
|---|---|---|
| cortex | cortex | NVIDIA workstation; DP-1 at 7680×2160@120, scale 1.25; Windows dual boot; Steam, gamescope, gamemode; Wayle; Tether Bluetooth support |
| brain-dongle | brain-dongle | NVIDIA GPU server; Hyprland and shared desktop apps still installed; vscode-server; DHCP on eno1/eno2 without NetworkManager; TCP ports 22 and 32400 open |
| nix1 | x1 | ThinkPad iGPU; Lenovo X1 11th-gen hardware module; NetworkManager; Waybar; Docker |
| razor | razor | Small host config with Docker and no NVIDIA module; still includes Hyprland and shared desktop apps; NetworkManager; Waybar |
| sparq-lappy | sparq-lappy | NixOS-WSL on x86_64; CLI tools, Docker, Tailscale, vscode-server; uses `users/ryan/wsl.nix` |

`hosts/common/base.nix` holds the boot-free settings every host shares (Nix
settings, GC, scheduling, zsh, Tailscale, locale, sudo, core packages).
`hosts/common/default.nix` imports it and adds the bootloader, user account,
console, printing, and fonts for native hosts. WSL imports `base.nix`
directly; do not import `default.nix` there. `users/ryan/cli.nix` shares CLI
packages, dotfiles, Git defaults, and install hooks across desktop and WSL
users. Keep personal Git identity, SSH hosts, and the Google Cloud project in
`default.nix`, `ssh.nix`, and out of the work profile. See `docs/wsl.md` for
the first user change, which requires `boot` and WSL restarts.

Preserve `nix1`'s `dir = "x1"`; use `hostName == "nix1"` in host checks.

All native hosts import Docker, Hyprland, and Vim. Cortex and brain-dongle also import NVIDIA and SSH. Cortex and nix1 import Bluetooth. Hyprland imports xremap. No host imports the Podman module.

Cortex and nix1 set up the hyprlock PAM service, GNOME Keyring, and power-button policy (short press suspends, long press powers off). Brain-dongle ignores the power button. Cortex also has a swap file, USB wake suppression, AirPlay discovery, and libvirt.

### Shared native system settings

- systemd-boot keeps five entries. Weekly garbage collection removes generations older than one week.
- Nix builds use idle CPU and I/O priority.
- `ryan` has passwordless sudo and groups `wheel`, `networkmanager`, `docker`, `input`, `libvirtd`, and `kvm`.
- Tailscale runs on all hosts. Join each host with `sudo tailscale up`; login state lives in `/var/lib/tailscale`.
- Printing and Avahi run on all hosts except brain-dongle. Cortex also uses Avahi for AirPlay.
- Common tools include `htop`, `nvtopPackages.full`, `jq`, and `curl`. Meslo Nerd Fonts supplies the monospace font.
- `allowUnfree` appears in `hosts/common/default.nix`, `users/ryan/configs/config.nix`, and `flake.nix`'s `nixConfig`. Review all three when changing that policy; they are distinct config locations.

### Docker and NVIDIA

All five hosts use the shared system Docker module, start it at boot, and disable rootless Docker. `ryan` uses the system daemon without sudo through the `docker` group. Preserve this choice: non-root container users and Dev Containers UID matching support writable host project and media folders. NVIDIA container support belongs only in `nvidia.nix`, imported by cortex and brain-dongle.

`make restart-docker` restarts only the system daemon. `make test-docker` uses `--device nvidia.com/gpu=all` with native CDI; it does not require a named NVIDIA runtime. Do not restore the old `virtualisation.docker.enableNvidia` option.

When applying the change to a host that used rootless Docker, inspect both daemons before stopping workloads. Their containers and volumes are separate; do not delete rootless data as part of this config change. Existing shells on nix1 may retain `DOCKER_HOST` pointing at the user socket: unset it or log in again, and check the Docker context.

The NVIDIA module selects the stable proprietary driver (`open = false`), enables CUDA and the container toolkit, adds the CUDA cache, and preserves video memory across suspend. Read its PipeWire capture workaround before changing screen sharing.

## Desktop and keybindings

`users/ryan/configs/hyprland.lua` holds the Lua desktop config. Home Manager also installs `hyprland.conf` for the session transition. Keep that fallback until Cortex has rebooted into Lua with no config errors.

- Cortex uses `wayle.nix` for the bar, notifications, and wallpaper. Wayle owns awww there. Other hosts use `waybar.nix` and the generated wallpaper startup script. Waybar shows a battery on nix1.
- Home Manager owns one hypridle service. Its raw config is `configs/hypr/hypridle.conf`, and config changes trigger a restart.
- Keep the 10-minute DPMS-off timer despite its documented NVIDIA failure risk. The user chose it; do not replace it with automatic suspend or DDC/CI. Read the dated notes in `hypridle.conf`.
- Raw files live in `users/ryan/configs/`; `home.file` maps them into the home directory. Ghostty's active settings live in `programs.ghostty` in `default.nix`.
- `configs/hypr/snap.sh` handles halves and corners. `portal-resize.sh` handles file dialogs; `power-menu.sh` handles power actions; `keybindings-menu.sh` reads named binds from the live session.
- Start long-running daemons and later actions separately. Chaining `awww-daemon && awww img ...` waits for the daemon to exit.

### Key rules

`Super` controls the desktop, except clipboard copy and paste. xremap maps `Super+C/V` to `Ctrl+C/V` in normal apps. Ghostty, Cursor, and Zed handle these keys themselves; VSCode, Wave, and Warp get terminal-safe chords. Preserve those exceptions. `Ctrl+C` must remain SIGINT/cancel in terminals; `Ctrl+Shift+C/V` copies and pastes.

- Super alone navigates; Super+Shift moves windows; Super+Alt resizes.
- `Super+Return` opens Ghostty; `Super+Shift+Return` opens Chrome; `Super+Shift+F` opens Cosmic Files.
- `Super+Space` opens the launcher; `Super+K` shows live keybindings.
- `Super+Q/W` closes; `Super+T` toggles floating; `Super+F` toggles fullscreen; `Super+M` moves to the master slot.
- `Super+1..0` selects workspaces; adding Shift moves the window there.
- Meh (Ctrl+Alt+Shift) plus arrows snaps to halves; Meh+Y/U/B/N selects top-left/top-right/bottom-left/bottom-right.
- `Super+L` and `Ctrl+Alt+L` lock; `Super+Escape` opens the power menu.

In `vscode.nix`, keep terminal overrides for Ctrl+J, Ctrl+E, Shift+Enter, and Shift+Tab. Ctrl+E explicitly sends byte `0x05`; Shift+Enter sends a backslash then carriage return. Shift+Tab sends ESC followed by `[Z`; its string contains a literal `0x1B` byte. Use `xxd` if that byte is unclear. Copy bindings also cover rendered webviews.

## Apps and known fixes

### Claude Desktop

`packages/claude-desktop/default.nix` packages Anthropic's official amd64 `.deb` for cortex and nix1. Do not restore the old `patrickjaja/claude-desktop-bin` or `claude-desktop-extra` inputs.

The non-flake `claude-desktop-repo` input locks Anthropic's apt index. Updates refresh it; the package selects the newest entry and fetches its `Filename` with its `SHA256`. It extracts the package without running apt setup scripts, then supplies an FHS runtime with desktop and Cowork VM needs.

Keep `--ozone-platform=wayland`, `--password-store=gnome-libsecret`, and the runtime `libsecret` library. Electron loads libsecret at run time, so `ldd` will not reveal its absence. Old revisions still need their upstream `.deb` or a retained store path; the lock does not archive upstream files.

### User tools

- Grok Bot is separate from the Grok coding CLI. Its local AppImage uses
  `grok-bot update`; see `docs/grok-bot.md`. Keep its NixOS wrapper and
  Home Manager menu entry: upstream AppImage menu setup bypasses the runtime.
  Clearing `APPIMAGE` prevents that setup but also disables in-app updates.
- Claude Code installs to `~/.local/bin/claude` through a first-run Home Manager hook. Keep this native install and its own update path, rather than a nixpkgs package or npx launch wrapper.
- Pi and Grok also have first-run install hooks outside the Nix store. Each installer is capped at 120 s and `mkHost` raises the Home Manager unit timeout to 15 min. Codex and Gemini use npx wrappers in `cli.nix`; their versions are not fixed by `flake.lock`.
- `packages/herdr/default.nix` wraps a versioned binary with a fixed hash.
- Handy excludes brain-dongle. Its override keeps ONNX Runtime on CPU to avoid the global CUDA rebuild, and a local patch adjusts its vLLM reasoning setting. Preserve the reasons in the adjacent comments.

### Session and app cautions

- After changing `home.sessionPath` or `home.sessionVariables`, warn the user that `exec zsh` alone may retain old values due to `__HM_SESS_VARS_SOURCED`. A fresh login is simplest. For a current terminal, use `unset __HM_SESS_VARS_SOURCED && exec zsh`; import an updated PATH with `systemctl --user import-environment PATH` where needed.
- Hyprland sets `NIXOS_OZONE_WL=1`; `default.nix` writes Code's Wayland flags. Preserve Wayland support for VSCode and Cursor.
- Chrome's flags disable `WaylandWpColorManagerV1`. GPU compositing stays enabled; the code notes that disabling it reduced Netflix quality.
- Neovim uses `vim.treesitter.start()` from a FileType callback. Do not restore the removed `nvim-treesitter.configs.setup` call.
- Nerd Fonts changed codepoints between major versions. Check a missing glyph with `fc-list :charset` against the installed font before replacing it.
