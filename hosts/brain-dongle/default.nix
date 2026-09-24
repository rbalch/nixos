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
    # ./timers.nix  # moved to openclaw
  ];

  nix.settings.download-buffer-size = 16777216; # 16 MiB

  programs.nix-ld.enable = true;
  programs.mtr.enable = true;

  environment.systemPackages = with pkgs; [
    cmatrix
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

  # Rendezvous key for sparq-lappy's reverse tunnel. That host cannot accept
  # inbound SSH (the Hyper-V firewall blocks it and opening it needs admin
  # rights the work account lacks), so it dials in here and binds port 2222
  # on loopback. Kept out of common/optional/sshd.nix because cortex shares
  # that file and has no reason to trust this key. `restrict` drops every
  # privilege, then only port forwarding comes back, and permitlisten pins it
  # to the one port: this key cannot open a shell.
  users.users.ryan.openssh.authorizedKeys.keys = [
    ''restrict,port-forwarding,permitlisten="2222" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDkxj6RgdQycayr0rL7WVVHHHRrxT6i5YrrRD8u42+oF ryan@sparq-lappy''
  ];

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

  # Cat-proof: ignore physical power button presses
  services.logind.settings.Login.HandlePowerKey = "ignore";

  system.stateVersion = "23.11";
}
