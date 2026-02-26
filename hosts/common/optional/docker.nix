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

  hardware.nvidia-container-toolkit.enable = true;

  users.extraGroups.docker.members = [ "ryan" ];
}
