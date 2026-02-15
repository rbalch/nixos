# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

NixOS flake-based configuration managing 4 Linux hosts + 1 macOS (standalone flake). Single user (ryan), home-manager integrated as a NixOS module.

## Build Commands

```bash
# Rebuild current host (must specify host name)
sudo nixos-rebuild switch --flake .#cortex      # or brain-dongle, nix1, razor

# Fresh install from GitHub
nixos-install --no-write-lock-file --impure --flake github:rbalch/nixos#<host>

# Update flake inputs
sudo nix flake update

# Cleanup old generations and garbage collect
sudo nix profile wipe-history --older-than 7d --profile /nix/var/nix/profiles/system
sudo nix store gc

# Test NVIDIA Docker
docker run --runtime=nvidia --device nvidia.com/gpu=all nvidia/cuda:12.8.1-base-ubuntu22.04 nvidia-smi
```

## Architecture

### Flake entry point (`flake.nix`)
- Tracks `nixpkgs-unstable` for all hosts
- Each host is a `nixosConfigurations.<name>` entry calling `nixpkgs.lib.nixosSystem`
- Home-manager is wired identically per-host (repeated block — candidate for DRY-ing up)
- `specialArgs` passes host-specific data (only some hosts use it)

### Host configs (`machines/`)
Mixed directory — contains both per-host subdirectories AND shared modules side-by-side:

**Per-host directories** (each has `configuration.nix` + `hardware-configuration.nix`):
- `cortex/` — Main workstation. Hyprland + NVIDIA + Docker
- `brain-dongle/` — GPU server. Docker + systemd timers + vscode-server
- `x1/` — ThinkPad laptop. Hyprland, no GPU. Uses `nixos-hardware` module
- `razor/` — Minimal laptop. Bare essentials
- `balch-huge/` — macOS (Apple Silicon). **Separate standalone flake**, nix-darwin

**Shared modules** (imported selectively by hosts):
- `desktop-hyprland.nix` — Hyprland WM + SDDM + XDG portals
- `nvidia.nix` — NVIDIA drivers + CUDA + modesetting
- `docker.nix` — Docker daemon + NVIDIA container toolkit (CDI-based)
- `ryan.nix` — User account, timezone, fonts, locale, sudo
- `sshd.nix` — OpenSSH server config
- `vim.nix` — Vim with plugins

### User config (`users/ryan/`)
Home-manager modules for the ryan user:
- `default.nix` — Package list, dotfile mappings, git, cursor theme
- `zsh.nix` — Zsh + powerlevel10k + oh-my-zsh + aliases
- `ssh.nix` — SSH client config (host aliases, identity files)
- `vscode.nix` — VS Code extensions + settings (immutable extensions)
- `waybar.nix` — Status bar styling and layout
- `configs/` — Static config files (hyprland.conf, ghostty.conf, p10k.zsh, etc.)

### Custom modules (`modules/`)
- `kitty/` — Kitty terminal config (just maps a config file via `xdg.configFile`)

## Key Patterns

- **allowUnfree** is set globally in `nixConfig` block and per-user in `configs/config.nix`
- **NVIDIA Docker** uses CDI standard: `--device nvidia.com/gpu=all` (not `--gpus`, which doesn't work on NixOS)
- **Home-manager** uses `useGlobalPkgs = true` and `useUserPackages = true` — user packages come from the system nixpkgs
- **Nix experimental features** `nix-command` and `flakes` are enabled in the flake's `nixConfig`
- Static config files live in `users/ryan/configs/` and are mapped to `~/.config/` paths via `home.file`

## Gotchas

- `nixpkgs` and `pkgsunstable` inputs both point to `nixpkgs-unstable` — they're currently identical
- The Makefile `rebuild` target doesn't specify a flake host — it relies on the system hostname matching a config name
- `machines/balch-huge/` is a fully separate flake (nix-darwin) — it's not part of the main flake's outputs
- Some hosts don't pass `specialArgs` (cortex, razor) while others do — modules that expect `hostName` in args will break on those hosts
