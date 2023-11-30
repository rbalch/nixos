{ config, pkgs, ...}:

{
    imports = [
        ./hardware-configuration.nix
        ../ryan.nix
        ../desktop-hyprland.nix
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
        curl
        fzf
        git
        jq
        vim
        wget
    ];

    networking = {
        hostName = "pixelNixer";
        enableIPv6 = false;
        networkmanager = {
            enable = true;
        };
        dhcpcd.wait = "background";
        firewall.enable = true;
    };

    # stop google-chrome vscode scaling (looks blurry otherwise)
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # Sound
    sound.enable = true;
    hardware.pulseaudio.enable = true;

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    system.stateVersion = "23.05";
}