{ ... }:

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    rootless.enable = false;
  };

  # Use the system daemon without sudo. NVIDIA support lives in nvidia.nix.
  users.extraGroups.docker.members = [ "ryan" ];
}
