{ config, pkgs, lib, hostName, ...}:

{
    imports = [
        ./hardware-configuration.nix
        ../ryan.nix
        ../desktop-hyprland.nix
        ../vim.nix
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nixpkgs.config.allowUnfree = lib.mkDefault true;

    environment.systemPackages = with pkgs; [
        curl
        fzf
        git
        gnumake
        htop
        jq
        killall
        lastpass-cli
        python3Full
        wget
    ];

    networking = {
        hostName = hostName;
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
    # limit number of boot options
    boot.loader.systemd-boot.configurationLimit = 5;

    # perform garbage collection weekly
    nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 1w";
    };

    # optimize store (ie: remove duplicates)
    nix.settings.auto-optimise-store = true;

    system.stateVersion = "23.11";

	virtualisation.docker = {
		enable = true;
		enableOnBoot = false;

		rootless = {
			enable = true;
			setSocketVariable = true;
		};
	};
	users.extraGroups.docker.members = [ "ryan" ];
}
