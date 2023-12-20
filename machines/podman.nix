{ config, pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        podman-compose
    ];

    virtualisation = {
        libvirtd.enable = true;
        podman = {
            enable = true;
            enableNvidia = true;
            dockerCompat = true;
            dockerSocket.enable = true;
            defaultNetwork.settings.dns_enabled = true;
        };
    };
    users.extraGroups.podman.members = [ "ryan" ];
}
