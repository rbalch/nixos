{ config, pkgs, ...}:

{
    imports = [
        ./hardware-configuration.nix
        ../ryan.nix
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    environment.systemPackages = with pkgs; [
        curl
        git
        vim
        wget
    ];

    networking = {
        hostName = "razor";
        enableIPv6 = false;
        networkmanager = {
            enable = true;
        };
        dhcpcd.wait = "background";
        firewall.enable = true;
    };

    environment.variables.EDITOR = "vim";

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    system.stateVersion = "23.05";
}