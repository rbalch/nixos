{ config, pkgs, lib, hostName, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common
    ../common/optional/hyprland.nix
    ../common/optional/vim.nix
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
    python3
    wget
  ];

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

  system.stateVersion = "23.11";
}
