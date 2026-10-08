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
    ../common/optional/openrig.nix
    ../common/optional/unas.nix
    ../common/optional/backup.nix
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
  # privilege, then port forwarding and pty come back, and permitlisten pins
  # the forward to the one port. pty is granted because sparq-lappy carries no
  # copy of the personal key, so users/ryan/ssh.nix points its `bd` entry at
  # this same key for interactive logins. Agent forwarding, X11 and user-rc
  # stay off.
  users.users.ryan.openssh.authorizedKeys.keys = [
    ''restrict,port-forwarding,pty,permitlisten="2222" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDkxj6RgdQycayr0rL7WVVHHHRrxT6i5YrrRD8u42+oF ryan@sparq-lappy''
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

  # Start Docker only once the NAS answers, so Plex (restart=unless-stopped)
  # finds /mnt/unas mounted. dhcpcd.wait = "background" means
  # network-online.target does not wait for a lease: on 2026-10-04 dockerd
  # touched the automount at 06:30:44, DNS failed, the mount failed, and Plex
  # stayed down. The wait gives up after 3 minutes, so a dead NAS delays
  # Docker but never blocks it; Docker only wants the mount.
  systemd.services.unas-wait = {
    description = "Wait for the UNAS SMB port";
    wantedBy = [ "multi-user.target" ];
    before = [ "mnt-unas.mount" "docker.service" ];
    path = [ pkgs.bash pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for _ in $(seq 90); do
        timeout 2 bash -c '</dev/tcp/nas.braindongle.com/445' 2>/dev/null && exit 0
        sleep 2
      done
      echo "nas.braindongle.com:445 unreachable after 3 minutes" >&2
    '';
  };
  systemd.services.docker = {
    wants = [ "unas-wait.service" "mnt-unas.mount" ];
    after = [ "unas-wait.service" "mnt-unas.mount" ];
  };

  # Cat-proof: ignore short power-button presses. A cover over the case
  # buttons (2026-10-04) blocks the long press and reset that this cannot;
  # see docs/brain-dongle-freezes.md.
  services.logind.settings.Login.HandlePowerKey = "ignore";

  system.stateVersion = "23.11";
}
