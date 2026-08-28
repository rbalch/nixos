# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

NixOS flake managing 4 Linux hosts + 1 standalone macOS flake. Single user (`ryan`). Home-manager integrated as a NixOS module (not standalone). Tracks `nixpkgs-unstable`.

## Build Commands

```bash
# Rebuild current host
make rebuild                       # = sudo nixos-rebuild switch --flake .#$(hostname)
make rebuild-nix1                  # = same, but explicit for the hostname≠dir host

# Fresh install
nixos-install --no-write-lock-file --impure --flake github:rbalch/nixos#<host>

# Maintenance
make update                        # sudo nix flake update (all inputs)
make cleanup                       # wipe-history >7d, then nix store gc
make garbage                       # nix-collect-garbage --delete-old
make test-docker                   # verify NVIDIA CDI runtime
make check-docker                  # docker info | grep runtime
make fix-vscode                    # re-patch vscode-server (brain-dongle)
```

`make rebuild` includes `git add -AN .` so newly-created files aren't invisible to flake builds (flakes ignore untracked files). Don't skip that step.

## Architecture

```
flake.nix
  ├── inputs: nixpkgs-unstable, home-manager, hyprland, nixos-hardware,
  │           vscode-server, xremap-flake, claude-desktop-repo
  └── outputs.nixosConfigurations.<host> = mkHost "<name>" { ... }
                                              ↓
                              lib/mkHost.nix
                                              ↓
                              hosts/<dir>/default.nix
                                + home-manager.users.ryan = users/ryan
```

### `lib/mkHost.nix`
```
mkHost hostname { system?, dir?, modules? }
```
- `system` defaults to `x86_64-linux`
- `dir` defaults to `hostname` (override for hostname/dirname mismatch — only nix1 does)
- `modules` is extra modules layered on top of `hosts/<dir>` and the home-manager wiring
- Always passes `inputs` and `hostName` via `specialArgs` AND `extraSpecialArgs` (so host modules and home-manager modules both see them)
- Home-manager: `useGlobalPkgs = true`, `useUserPackages = true`, `backupFileExtension = "hm-backup"`

## Hosts

| host         | dir            | hw                    | role                                                |
|--------------|----------------|-----------------------|-----------------------------------------------------|
| `cortex`     | `cortex`       | NVIDIA, ultrawide DP-1 7680×2160@120 scale 1.25 | Main workstation. Dual-boot Windows. Steam + gamemode. |
| `brain-dongle` | `brain-dongle` | NVIDIA               | GPU server. vscode-server module. firewall, no networkmanager. |
| `nix1`       | `x1`           | none (ThinkPad iGPU)  | ThinkPad. `nixos-hardware.lenovo-thinkpad-x1-11th-gen`. Rootless Docker. |
| `razor`      | `razor`        | none                  | Minimal laptop. No Docker, no NVIDIA, bare essentials. |

**Quirk**: `nix1` is the only host where hostname ≠ dir — its `mkHost` call uses `dir = "x1"`. Don't normalize this without checking why (probably historical).

Standalone: `machines/balch-huge/` is a separate **nix-darwin** flake. Not part of `outputs` here. Ignore unless explicitly working on the Mac.

## Hosts/common

**`hosts/common/default.nix`** — base for ALL hosts:
- Bootloader: systemd-boot, `configurationLimit = 5`, EFI variables ok
- Nix: flakes enabled, auto-optimise-store, daemon at idle CPU/IO priority (yields to interactive work)
- GC: weekly automatic, `--delete-older-than 1w`
- User `ryan`: wheel/networkmanager/docker/input, zsh shell, `NOPASSWD` sudo
- Fonts: noto fonts (incl CJK + emoji), font-awesome, **`nerd-fonts.meslo-lg`**, fontconfig defaults to Meslo for monospace
- Locale: en_US.UTF-8, terminus_font console, timezone America/New_York
- **Baseline packages: `htop`, `nvtopPackages.full`** (multi-vendor GPU monitor — works on all 4 hosts)
- `services.udisks2.enable = true`, `programs.zsh.enable = true`
- `allowUnfree = lib.mkDefault true` (note: also set in `flake.nix` `nixConfig` and `users/ryan/configs/config.nix` — see Gotchas)

**`hosts/common/optional/`** — opt-in, imported per-host:
| module | what it does | used by |
|--------|--------------|---------|
| `hyprland.nix` | Hyprland + SDDM (sddm-astronaut, `black_hole` preset) + uWSM + XDG portals + xkb us | cortex, brain-dongle, nix1, razor |
| `nvidia.nix` | nvidia drivers (`stable` package, `open=false`), modesetting, CUDA, cuda-maintainers cachix, container-toolkit, NVreg_PreserveVideoMemoryAllocations=1 | cortex, brain-dongle |
| `docker.nix` | Rootless Docker, `enableOnBoot=false`, `setSocketVariable=false`, container-toolkit, adds ryan to docker group | cortex |
| `sshd.nix` | OpenSSH server, pubkey-only (no passwords/kbdint), pre-loaded `authorized_keys` for ryan | cortex, brain-dongle |
| `vim.nix` | `vim-full` w/ plugins (copilot-vim, nerdtree, vim-airline, undotree, vim-lastplace, vim-nix, vista-vim), `hlsearch`+`incsearch`, mouse, F2/F5/F8 toggles, ctags | cortex, brain-dongle, nix1, razor |
| `podman.nix` | Podman runtime (exists, not currently imported anywhere) | — |
| `xremap.nix` | legacy per-app Mac-style Super→Ctrl rules; retained for reference during the key-map trial | — |

**Notes on per-host extras** (not in optional/):
- `cortex/default.nix`: dual-boot Windows entry, `programs.nix-ld.enable`, Steam + gamescope + gamemode, `disable-usb-wakeup` oneshot (XHCI wake suppression), `services.logind.settings.Login` (short-press = suspend, long-press = poweroff), pam.hyprlock, gnome-keyring
- `brain-dongle/default.nix`: bigger download buffer, no networkmanager (static eno1/eno2 + dhcpcd), firewall opens 22 + 32400, `virtualisation.docker.enableNvidia = true` (separate from docker.nix module)
- `x1/default.nix` (host nix1): `programs.nix-ld.enable`, rootless Docker inline (NOT from docker.nix module — it has its own setup), same logind power-button policy as cortex, pam.hyprlock, gnome-keyring
- `razor/default.nix`: barest of bones

## User config (`users/ryan/`)

```
users/ryan/
├── default.nix     # packages, dotfile mappings, git, ghostty, password-store,
│                   # home.sessionVariables, home.sessionPath, claudeCodeBootstrap activation
├── nvim.nix        # programs.neovim w/ plugins, withRuby/Python3 off
├── ssh.nix         # ssh client host aliases (bd, dgx, github, huggingface)
├── vscode.nix      # immutable extensions, keybindings overrides (see Keybinding system)
├── waybar.nix      # transparent waybar, hyprland workspaces module, conditional battery on nix1
├── zsh.nix         # powerlevel10k + oh-my-zsh (git, history) + fzf
├── backgrounds/    # static wallpaper assets
└── configs/        # raw files mapped via home.file
    ├── hyprland.conf
    ├── ghostty.conf, tmux.conf, p10k.zsh, config.nix
    ├── hypr/
    │   ├── hypridle.conf, hyprlock.conf
    │   ├── snap-right.sh    # bound to Super+]
    │   ├── power-menu.sh    # bound to Super+Escape
    │   └── keybindings-menu.sh # searchable live Hyprland key list
    └── nvim/init.lua        # baked into nvim via builtins.readFile
```

## Claude Desktop package

`packages/claude-desktop/default.nix` packages Anthropic's official Linux `.deb` for `cortex` and `nix1` only. Do not restore the old `patrickjaja/claude-desktop-bin` or `patrickjaja/claude-desktop-extra` GitHub inputs.

- `claude-desktop-repo` is a non-flake input that locks Anthropic's official amd64 apt `Packages` index.
- `make update` refreshes that index with the other flake inputs. The local package parses all `claude-desktop` entries, selects the newest version, and uses its `Filename` and `SHA256` fields to fetch the `.deb`.
- The package extracts the `.deb` without running its apt setup scripts, then runs it in an FHS environment with its desktop, keyring, tray, audio, and Cowork VM needs.
- The launcher always passes `--ozone-platform=wayland` and `--password-store=gnome-libsecret`. Keep `libsecret` in the FHS library set: Electron loads it at run time, so `ldd` does not report it when it is absent.
- The package scope checks `hostName` against `[ "cortex" "nix1" ]`; the ThinkPad's host name remains `nix1` even though its directory is `x1`.
- Old Git revisions still need their versioned `.deb` in Anthropic's pool or a retained Nix store path. The lock fixes the index and hashes, but it does not archive upstream files.

## Keybinding system

`Super` belongs to Hyprland. Apps use their normal Linux `Ctrl` keys. Cortex no longer imports xremap, so new apps need no per-app Super→Ctrl rules. Use `Ctrl+Shift+C/V` for copy and paste in terminals.

### Hyprland binds — `users/ryan/configs/hyprland.conf`

OS-first — `$mainMod = SUPER`. Window management and app shortcuts:

- `Super+Q` or `Super+W` → close window
- `Super+T` → toggle floating/tiling
- `Super+Return` → Ghostty; `Super+Shift+Return` → Chrome; `Super+Shift+F` → cosmic-files
- `Super+Space` → app launcher; `Super+K` → searchable live key list
- `Super+F` → full screen
- `Super+M` → move the focused window to the center master slot
- `Super+1..0` → workspace 1..10, `Super+Shift+1..0` → move window to workspace
- `Super+arrows` → movefocus, `Super+Shift+arrows` → swapwindow, `Super+Alt+arrows` → resizeactive
- `Meh+arrows` → snap to half-screen (`snap.sh left/right/top/bottom`). Meh = Ctrl+Alt+Shift, single-key on Moonlander.
- `Meh+Y/U/B/N` → snap to corner — 2x2 grid (Y=TL, U=TR, B=BL, N=BR).
- `Super+LMB/RMB drag` → move/resize
- Mouse swipe-3 → workspace next/prev

**Spatial mod pattern (consistent across arrows and numbers):**
| Modifier | Verb |
|---|---|
| Super alone | navigate (movefocus, workspace switch) |
| Super+Shift | move this window (swapwindow, movetoworkspace) |
| Super+Alt | resize this window |

Sleep / lock / power (`# sleep and lock` section):

- `Super+L` → lock
- `Ctrl+Alt+L` → lock
- `Super+Escape` → power menu (`power-menu.sh` — Lock / Screen Off / Suspend / Logout / Reboot / Shutdown)
- Power button: short = suspend, long = poweroff (configured per-host in `services.logind.settings.Login` on cortex + x1)

### VSCode overrides — `users/ryan/vscode.nix` `keybindings`

These keep terminal and TUI keys useful inside VSCode:

- `Ctrl+J` unbound from `togglePanel` (so it can pass through to terminal as LF = newline)
- `Ctrl+Shift+C` editor → editor copy (default was openNativeConsole, useless); terminal default already copies selection
- `Ctrl+Shift+V` editor → paste (default unbound on editor)
- `Super+C/V` in `terminalFocus` → copy selected text / paste; `Ctrl+C` remains SIGINT/cancel
- `Ctrl+E` in `terminalFocus` → unbound from quickOpen (so terminal gets end-of-line readline)
- `Shift+Enter` in `terminalFocus` → sends `\n` (Claude Code newline / TUI newline)
- `Shift+Tab` in `terminalFocus` → sends CSI Z (back-tab, Claude Code mode cycle: Plan / Accept-edits / Default). **The `args.text` string contains a literal ESC byte (0x1B) that's invisible in plain text — verify with `xxd` if it looks like just `"[Z"`.**

## Key patterns

- **mkHost** handles all boilerplate — adding a new host is a new `hosts/<name>/` dir + one line in `flake.nix`
- **Super is for the OS.** Do not add app-specific Super remaps. Use normal Linux `Ctrl` shortcuts in apps.
- **`Ctrl+C` is sacred in terminals.** It stays SIGINT/cancel. `Ctrl+Shift+C` remains the standard clipboard copy key.
- **Ghostty clipboard:** `Super+C/V` copy and paste because Hyprland leaves those chords free; `Ctrl+C` remains SIGINT/cancel.
- **NVIDIA Docker uses CDI**: `docker run --runtime=nvidia --device nvidia.com/gpu=all ...`. NOT `--gpus all` (that's docker desktop / non-nixos).
- **Home-manager** uses `useGlobalPkgs = true` — user packages come from the *system* nixpkgs, no second pkgs evaluation.
- **Static config files** live in `users/ryan/configs/` and map to `~/.config/...` via `home.file` in `users/ryan/default.nix`.
- **Claude Code install pattern**: NOT `pkgs.claude-code` (too slow a cadence), NOT npx wrapper (popups). Instead: home-manager activation script bootstraps native install to `~/.local/bin/claude` on first rebuild via `npx --yes @anthropic-ai/claude-code@latest install latest`, idempotent. Claude's own self-updater handles upgrades thereafter. `DISABLE_AUTOUPDATER=1` silences the nag. See `home.activation.claudeCodeBootstrap` in `users/ryan/default.nix`. `codex` and `gemini` are still npx wrappers (not in nixpkgs).

## Gotchas

- **TODO after the next Cortex reboot:** Confirm Cortex starts with `~/.config/hypr/hyprland.lua` and has no config errors, then remove `users/ryan/configs/hyprland.conf` and its `home.file` mapping from `users/ryan/default.nix`. The `.conf` file exists only as a fallback for the Cortex session that was running during the Lua move.
- **`allowUnfree` set in 3 places**: `flake.nix` `nixConfig`, `hosts/common/default.nix` (`mkDefault`), `users/ryan/configs/config.nix`. Touch all three when changing.
- **`__HM_SESS_VARS_SOURCED` guard kills sessionPath/sessionVariables updates in running sessions.** After adding/changing `home.sessionPath` or `home.sessionVariables`, `exec zsh` *won't* pick them up because the guard env var is inherited from the parent and `hm-session-vars.sh` short-circuits. Recovery: `unset __HM_SESS_VARS_SOURCED && exec zsh` for the current terminal, `systemctl --user import-environment PATH` for the Hyprland tree, or just logout/login (cleanest). Warn the user explicitly when proposing these changes.
- **VSCode + Cursor need Wayland flags**: `NIXOS_OZONE_WL=1` (set in `users/ryan/default.nix` env files + Hyprland conf) and `~/.config/code-flags.conf = "--ozone-platform=wayland"`.
- **Chrome needs Wayland flags**: see `.config/chrome-flags.conf` in `users/ryan/default.nix` — disables `WaylandWpColorManagerV1` and `gpu-compositing` to prevent crash on DPMS off / suspend.
- **`exec-once` in hyprland.conf with `&&` against long-running daemons is a trap.** Use two `exec-once` lines: one to start the daemon, one with `sleep N && cmd` to do follow-up. Bit us on `awww-daemon && awww img ...` showing black background.
- **nvim treesitter API rewrite.** Current nixpkgs nvim-treesitter ships the "main" branch — `require("nvim-treesitter.configs").setup(...)` is gone. Use built-in `vim.treesitter.start()` from a FileType autocmd. Already wired in `users/ryan/configs/nvim/init.lua`.
- **Nerd Fonts v3 codepoint reorganization.** Some glyphs moved from old PUA in v2. If a glyph in `users/ryan/waybar.nix` renders as blank, verify the codepoint with `fc-list :charset` against the installed font (currently `nerd-fonts.meslo-lg 3.4.0+1.21`).
- **`configuration.nix` in repo root** appears to be a leftover/legacy file (referenced by Makefile's `sync-in`/`install`/`get-config` targets). Not part of the flake — don't edit unless explicitly working on bare-install/recovery paths.
