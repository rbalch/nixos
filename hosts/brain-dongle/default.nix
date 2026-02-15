{ config, pkgs, lib, hostName, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common
    ../common/optional/hyprland.nix
    ../common/optional/nvidia.nix
    ../common/optional/docker.nix
    ../common/optional/sshd.nix
    ../common/optional/vim.nix
    ./timers.nix
  ];

  nix.settings.download-buffer-size = 16777216; # 16 MiB

  programs.nix-ld.enable = true;
  programs.mtr.enable = true;

  environment.systemPackages = with pkgs; [
    cmatrix
    curl
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
    hostName = hostName;
    enableIPv6 = false;
    networkmanager.enable = false;
    interfaces.eno1.useDHCP = true;
    interfaces.eno2.useDHCP = true;
    dhcpcd.wait = "background";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 32400 ];
    };
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

  virtualisation.docker.enableNvidia = true;

  system.stateVersion = "23.11";
}
