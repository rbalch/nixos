# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

NixOS flake-based configuration managing 4 Linux hosts + 1 macOS (standalone flake). Single user (ryan), home-manager integrated as a NixOS module.

## Build Commands

```bash
# Rebuild current host (auto-detects hostname)
make rebuild
# Or explicitly:
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
- Uses `lib/mkHost.nix` helper — each host is a one-liner with optional extra modules
- Home-manager and `specialArgs` are wired up automatically by `mkHost`
- `specialArgs` always passes `inputs` and `hostName` to all hosts

### `lib/mkHost.nix`
Helper function: `mkHost hostname { system, dir, modules }` → `nixosSystem` attrset.
- Defaults: `system = "x86_64-linux"`, `dir = hostname`
- Imports the host's `hosts/<dir>/default.nix` + any extra `modules`
- Wires home-manager with `useGlobalPkgs` and `useUserPackages`

### Host configs (`hosts/`)
```
hosts/
  common/
    default.nix              # Base config ALL hosts get (boot, nix, user, fonts, locale, sudo, gc)
    optional/
      docker.nix             # Docker daemon + NVIDIA container toolkit (CDI-based)
      hyprland.nix           # Hyprland WM + SDDM + XDG portals
      nvidia.nix             # NVIDIA drivers + CUDA + modesetting
      podman.nix             # Podman container runtime
      sshd.nix               # OpenSSH server config
      vim.nix                # Vim with plugins
  cortex/                    # Main workstation. Hyprland + NVIDIA + Docker
  brain-dongle/              # GPU server. Docker + systemd timers + vscode-server
  x1/                        # ThinkPad laptop (nix1). Hyprland, no GPU
  razor/                     # Minimal laptop. Bare essentials
```

Each per-host `default.nix` imports `../common` + relevant `../common/optional/*` modules + host-specific settings.

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

### macOS (`machines/balch-huge/`)
Standalone nix-darwin flake, not part of the main flake's outputs.

## Key Patterns

- **`mkHost`** handles all boilerplate — adding a new host is just a new `hosts/<name>/` dir + one line in `flake.nix`
- **`hosts/common/default.nix`** is imported by every host — contains boot, nix settings, user account, fonts, locale, sudo, gc
- **`hosts/common/optional/`** modules are opt-in — each host picks what it needs via imports
- **allowUnfree** is set in `nixConfig` block, in `hosts/common/default.nix` (mkDefault), and per-user in `configs/config.nix`
- **NVIDIA Docker** uses CDI standard: `--device nvidia.com/gpu=all` (not `--gpus`, which doesn't work on NixOS)
- **Home-manager** uses `useGlobalPkgs = true` and `useUserPackages = true` — user packages come from the system nixpkgs
- Static config files live in `users/ryan/configs/` and are mapped to `~/.config/` paths via `home.file`

## Gotchas

- The `nix1` host uses `dir = "x1"` in mkHost — the hostname doesn't match the directory name
- `machines/balch-huge/` is a fully separate flake (nix-darwin) — it's not part of the main flake's outputs
