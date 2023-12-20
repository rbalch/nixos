{ config, pkgs, ... }:

{
    # environment.systemPackages = with pkgs; [
    #     podman-compose
    # ];

    # virtualisation = {
    #     libvirtd.enable = true;
    #     podman = {
    #         enable = true;
    #         enableNvidia = true;
    #         dockerCompat = true;
    #         dockerSocket.enable = true;
    #         defaultNetwork.settings.dns_enabled = true;
    #     };
    # };
    # users.extraGroups.podman.members = [ "ryan" ];

  virtualisation = {
    containers.enable = true;
    containers.storage.settings = {
      storage = {
        driver = "overlay";
        runroot = "/run/containers/storage";
        graphroot = "/var/lib/containers/storage";
        rootless_storage_path = "/tmp/containers-$USER";
        options.overlay.mountopt = "nodev,metacopy=on";
      };
    };

    oci-containers.backend = "podman";
    podman = {
      enable = true;
      enableNvidia = true;
      dockerCompat = true;
      # extraPackages = [ pkgs.zfs ]; # Required if the host is running ZFS
    };
  };

  environment.systemPackages = with pkgs; [ docker-compose ];
  environment.extraInit = ''
    if [ -z "$DOCKER_HOST" -a -n "$XDG_RUNTIME_DIR" ]; then
      export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
    fi
  '';
}
