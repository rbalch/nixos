{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../desktop-hyprland.nix
      ../nvidia.nix
      ../docker.nix
      ../ryan.nix
      ../vim.nix
      ../sshd.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "cortex";

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  }

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11"; # Did you read the comment?
}
