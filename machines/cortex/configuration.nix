{ config, lib, pkgs, ... }:

{
  fileSystems."/boot/windows-efi" = {
    device = "/dev/disk/by-uuid/C01B-8E21";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" "ro" ];
  };

  boot.loader.systemd-boot.extraEntries."windows.conf" = ''
    title Windows
    efi /windows-efi/EFI/Microsoft/Boot/bootmgfw.efi
  '';

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

    environment.systemPackages =
        (with pkgs; [
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
            python3Full
            tmux
            wget
            unzip
            uv
        ]);

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "cortex";

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Lock screen
  security.pam.services.hyprlock = {};

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11"; # Did you read the comment?
}