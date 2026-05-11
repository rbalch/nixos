{ config, pkgs, lib, hostName, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common
    ../common/optional/hyprland.nix
    ../common/optional/vim.nix
    ../common/optional/xremap.nix
  ];

  environment.systemPackages = with pkgs; [
    curl
    fzf
    git
    gnumake
    htop
    jq
    killall
    lastpass-cli
    nodejs
    python3
    wget
  ];

  # compatability shim - so stuff like npx and vscode can work
  programs.nix-ld.enable = true;

  networking = {
    hostName = hostName;
    enableIPv6 = false;
    networkmanager.enable = true;
    dhcpcd.wait = "background";
    firewall.enable = true;
  };

  # stop google-chrome vscode scaling (looks blurry otherwise)
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Local Docker (rootless, no GPU)
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  users.extraGroups.docker.members = [ "ryan" ];

  # Power button: short press = suspend, long press = poweroff
  services.logind.settings.Login = {
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };

  # Lock screen
  security.pam.services.hyprlock = {};

  # Keyring: unlock on SDDM login so libsecret clients can store/retrieve secrets
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  system.stateVersion = "23.11";
}
