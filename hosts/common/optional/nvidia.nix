{ config, pkgs, lib, ... }:

{
  # Screen sharing fix (Chrome/Meet, Slack, OBS-via-portal).
  #
  # xdg-desktop-portal-hyprland negotiates DMA-BUF with *explicit* modifiers.
  # Against the NVIDIA proprietary driver the modifier fixation handshake fails:
  #     [pw] Building modifiers for dma
  #     [screencopy/pipewire] Out of buffers
  #     [ERR] [pw] DMA-BUF fixation failed after 2 attempts, falling back to SHM
  #     [WARN] [pipewire] Asked for a wl_shm buffer which is legacy.
  # The legacy SHM fallback then streams solid black. Forcing implicit modifiers
  # keeps capture on the working DMA-BUF path.
  # Upstream: https://github.com/hyprwm/xdg-desktop-portal-hyprland/issues/48
  services.pipewire.extraConfig.pipewire."10-no-dmabuf-modifiers" =
    lib.mkIf config.services.pipewire.enable {
      "context.properties" = {
        "support.dmabuf" = true;
        "support.dmabuf.modifiers" = false;
      };
    };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];
  nixpkgs.config.cudaSupport = true;

  # Pre-built CUDA-enabled binaries — avoids local rebuilds of opencv/ffmpeg/etc.
  nix.settings = {
    extra-substituters = [ "https://cuda-maintainers.cachix.org" ];
    extra-trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  hardware.nvidia-container-toolkit.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = true;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    open = false;
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
  ];

  # wake after sleep stuff
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
}
