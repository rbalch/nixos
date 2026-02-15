{ config, pkgs, ... }:

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
    jq
    killall
    lastpass-cli
    wget
  ];

  networking = {
    hostName = "razor";
    enableIPv6 = false;
    networkmanager.enable = true;
    dhcpcd.wait = "background";
    firewall.enable = true;
  };

  system.stateVersion = "23.11";
}
