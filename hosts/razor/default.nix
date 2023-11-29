{ config, pkgs, ... }:

{
    imports = [
        ./networking.nix
        ./udisk.nix
    ];

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    time.timeZone = "America/New_York";
}