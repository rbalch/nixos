{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common
    ../common/optional/hyprland.nix
    ../common/optional/nvidia.nix
    ../common/optional/docker.nix
    ../common/optional/sshd.nix
    ../common/optional/vim.nix
  ];

  # Windows dual-boot
  boot.loader.systemd-boot = {
    windows."windows" = {
      title = "Windows";
      efiDeviceHandle = "FS1";  # may need adjusting
      sortKey = "y_windows";
    };
    edk2-uefi-shell.enable = true;
    edk2-uefi-shell.sortKey = "z_edk2";
  };

  environment.systemPackages = with pkgs; [
    cmatrix
    curl
    dconf
    dig
    direnv
    fzf
    ghostty.terminfo
    git
    git-lfs
    gnumake
    jq
    killall
    lastpass-cli
    ngrok
    nodejs
    python3
    tmux
    wget
    unzip
    uv
  ];

  networking = {
    hostName = "cortex";
    networkmanager.enable = true;
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Lock screen
  security.pam.services.hyprlock = {};

  system.stateVersion = "25.11";
}
