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
        lastpass-cli
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

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    system.stateVersion = "23.11";
}