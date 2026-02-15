# NVIDIA GPU in Docker on NixOS

## Overview

NixOS uses **CDI (Container Device Interface)** to expose NVIDIA GPUs to Docker containers. The older `--gpus` flag does **not** work with this setup. Use `--device` instead.

## Configuration

In `machines/docker.nix`:

```nix
{ config, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    rootless = {
      enable = true;
      setSocketVariable = false;
    };
  };

  hardware.nvidia-container-toolkit.enable = true;

  users.extraGroups.docker.members = [ "ryan" ];
}
```

`hardware.nvidia-container-toolkit.enable` handles everything — CDI spec generation, runtime registration, device exposure. **Do not** manually configure `daemon.settings.runtimes` or reference `pkgs.nvidia-docker`.

## Running GPU Containers

```bash
# ✅ CORRECT — use CDI device flag
docker run --rm --device nvidia.com/gpu=all nvidia/cuda:13.1.1-base-ubuntu24.04 nvidia-smi

# ❌ WRONG — --gpus flag uses old runtime approach, will fail
docker run --rm --gpus all nvidia/cuda:13.1.1-base-ubuntu24.04 nvidia-smi
# Error: could not select device driver "" with capabilities: [[gpu]]
```

## How It Works

1. A systemd service (`nvidia-container-toolkit-cdi-generator`) runs at boot
2. It generates a CDI spec at `/run/cdi/nvidia-container-toolkit.json`
3. Docker's CDI integration reads this spec and exposes `nvidia.com/gpu=all` and `nvidia.com/gpu=0` devices
4. Containers get GPU access via `--device nvidia.com/gpu=all`

## Troubleshooting

### Verify CDI spec exists

```bash
ls -la /run/cdi/
# Should contain nvidia-container-toolkit.json
```

### Verify Docker sees CDI devices

```bash
docker info 2>&1 | grep -i cdi
# Should show:
#   CDI spec directories: /etc/cdi /run/cdi
#   cdi: nvidia.com/gpu=0
#   cdi: nvidia.com/gpu=all
```

### Verify the generator service ran

```bash
systemctl status nvidia-container-toolkit-cdi-generator
```

### If CDI spec is missing

```bash
sudo systemctl restart nvidia-container-toolkit-cdi-generator
sudo systemctl restart docker
```

### Common pitfall after `nix flake update`

The old `pkgs.nvidia-docker` / manual runtime config in `daemon.settings.runtimes` breaks after upgrades. Remove all manual runtime configuration and rely solely on `hardware.nvidia-container-toolkit.enable = true`.