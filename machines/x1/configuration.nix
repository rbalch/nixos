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
        hostName = "nix1";
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
    security.rtkit.enable = true;
    services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        # If you want to use JACK applications, uncomment this
        #jack.enable = true;
    };

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    system.stateVersion = "23.11";
}