{ inputs, pkgs, hostName, ... }:

{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    # WSL handles boot and hardware, so import the boot-free base rather
    # than hosts/common/default.nix.
    ../common/base.nix
    ../common/optional/docker.nix
    # Inbound SSH from the LAN. Reaching it also needs WSL-side plumbing on
    # Windows (mirrored networking or a portproxy); see docs/wsl.md.
    ../common/optional/sshd.nix
    inputs.vscode-server.nixosModules.default
  ];

  wsl.enable = true;
  # NixOS-WSL creates this user with the wheel group; docker.nix adds docker.
  wsl.defaultUser = "ryan";
  networking.hostName = hostName;
  services.vscode-server.enable = true;

  # Reverse SSH tunnel to brain-dongle. WSL sits behind the Hyper-V firewall,
  # whose inbound default is Block, and adding a rule there needs local
  # administrator rights this work account does not have. Outbound is allowed,
  # so dial out instead and publish this host's sshd on bd's loopback as port
  # 2222. Reachable only on the home LAN: bd.braindongle.com is NXDOMAIN in
  # public DNS. See docs/wsl.md.
  systemd.services.reverse-tunnel = {
    description = "Reverse SSH tunnel publishing local sshd on brain-dongle";
    after = [ "network.target" "sshd.service" ];
    wantedBy = [ "multi-user.target" ];

    # Never stop retrying; the laptop sleeps and moves between networks.
    unitConfig.StartLimitIntervalSec = 0;

    serviceConfig = {
      User = "ryan";
      Restart = "always";
      RestartSec = 10;
      # No autossh: systemd already supervises, and the keepalives below drop
      # a dead link within ~90 s so Restart picks it up. ExitOnForwardFailure
      # matters because without it a refused port bind still yields a live
      # connection with no tunnel, which systemd would see as healthy.
      ExecStart = ''
        ${pkgs.openssh}/bin/ssh -NT \
          -o ExitOnForwardFailure=yes \
          -o ServerAliveInterval=30 \
          -o ServerAliveCountMax=3 \
          -o StrictHostKeyChecking=accept-new \
          -o IdentitiesOnly=yes \
          -o BatchMode=yes \
          -i /home/ryan/.ssh/id_ed25519 \
          -R 2222:localhost:22 \
          ryan@bd.braindongle.com
      '';
    };
  };

  # Native CLI installers download binaries that expect a standard Linux loader.
  programs.nix-ld.enable = true;
  users.users.ryan.shell = pkgs.zsh;

  environment.systemPackages = with pkgs; [ git gnumake vim ];

  # Keep this fixed after the first install; it controls state compatibility.
  system.stateVersion = "26.11";
}
