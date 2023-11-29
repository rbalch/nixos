{ config, pkgs, ... }:

{
    imports = [
        ./hardware-configuration.nix
        ./networking.nix
        ./udisk.nix
    ];

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    time.timeZone = "America/New_York";
}