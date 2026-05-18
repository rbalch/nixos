{ config, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    rootless = {
      enable = true;
      setSocketVariable = false;
    };
  };

  # pasta replaces slirp4netns for rootless docker networking — much higher
  # throughput (near line-rate) and lower CPU. Picked up by dockerd-rootless.sh
  # via the env vars below.
  environment.systemPackages = [ pkgs.passt ];

  systemd.user.services.docker = {
    environment = {
      DOCKERD_ROOTLESS_ROOTLESSKIT_NET = "pasta";
      DOCKERD_ROOTLESS_ROOTLESSKIT_PORT_DRIVER = "implicit";
    };
    # rootlesskit shells out to `pasta`; make it visible to the user service
    path = [ pkgs.passt ];
  };

  hardware.nvidia-container-toolkit.enable = true;

  users.extraGroups.docker.members = [ "ryan" ];
}
