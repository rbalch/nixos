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
      efiDeviceHandle = "FS0";
      sortKey = "y_windows";
    };
    edk2-uefi-shell.enable = true;
    edk2-uefi-shell.sortKey = "z_edk2";
  };

  # compatability shim - so stuff like npx and vscode can work
  programs.nix-ld.enable = true;

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

  # Gaming
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    package = pkgs.steam.override {
      extraEnv = {
        STEAM_ENABLE_WAYLAND = true;
        STEAM_FORCE_DESKTOPUI_SCALING = 1.25;
      };
    };
  };
  programs.gamemode.enable = true;

  # Prevent USB controller from waking system immediately after suspend
  systemd.services.disable-usb-wakeup = {
    description = "Disable XHCI USB wakeup";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "disable-usb-wakeup" ''
        grep -q "^XHCI.*enabled" /proc/acpi/wakeup && echo XHCI > /proc/acpi/wakeup || true
      '';
    };
  };

  # Lock screen
  security.pam.services.hyprlock = {};

  # Keyring: unlock on SDDM login so libsecret clients (vscode, etc.) can store/retrieve secrets
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  system.stateVersion = "25.11";
}
