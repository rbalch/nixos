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
    ../common/optional/xremap.nix
    ../common/optional/bluetooth.nix
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

  # Swap file on root disk — 62 GiB RAM is plenty for normal use, but heavy
  # parallel C++ builds (OrcaSlicer, NVIDIA kmod) spike memory hard enough
  # to trigger systemd-oomd kills. Without swap there's nowhere to spill,
  # so the OOM killer murders the build (or the compositor, or both) and
  # we end up with black-screen-and-coredumps. 16 GiB is overkill for a
  # safety net but cheap on disk.
  swapDevices = [
    { device = "/var/lib/swapfile"; size = 16 * 1024; }  # MiB
  ];

  environment.systemPackages = with pkgs; [
    cmatrix
    dconf
    dig
    direnv
    fzf
    ghostty.terminfo
    git
    git-lfs
    gnumake
    killall
    lastpass-cli
    ngrok
    nodejs
    python3
    tmux
    wget
    unzip
    uv
    quickemu
    figma-linux
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

  # Modern Proton/DXVK games (OW2 et al) blow past the default 65530 mmap
  # limit and crash silently. Steam Deck / Fedora / Arch-steam ship this
  # value; it's a ceiling, not an allocation.
  boot.kernel.sysctl."vm.max_map_count" = 2147483642;

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

  # Power button: short press = suspend (default is poweroff, footgun), long press = poweroff
  services.logind.settings.Login = {
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };

  # Lock screen
  security.pam.services.hyprlock = {};

  # Keyring: unlock on SDDM login so libsecret clients (vscode, etc.) can store/retrieve secrets
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # macOS VM via QEMU/KVM — kvm-intel already loaded in hardware-configuration.nix
  virtualisation.libvirtd.enable = true;

  system.stateVersion = "25.11";
}
