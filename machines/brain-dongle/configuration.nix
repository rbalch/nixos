{ config, pkgs, lib, hostName, pkgsunstable, ...}:

{
    imports = [
        ./hardware-configuration.nix
        ../docker.nix
        ../nvidia.nix
        # ../podman.nix
        ../ryan.nix
        ../sshd.nix
        ../desktop-hyprland.nix
        ../vim.nix
        ./timers.nix
    ];

    nix.settings = {
        download-buffer-size = 16777216; # 16 MiB
        experimental-features = [ "nix-command" "flakes" ];
    };

    # nix.settings.download-buffer-size = 16777216; # 16 MiB
    # nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nixpkgs.config.allowUnfree = lib.mkDefault true;
    programs.nix-ld.enable = true;
    programs.mtr.enable = true;

    environment.systemPackages =
        (with pkgs; [
            cmatrix
            curl
            dig
            direnv
            fzf
            ghostty.terminfo
            git
            git-lfs
            gnumake
            jq
            killall
            lastpass-cli
            ngrok
            nodejs
            python3Full
            tmux
            wget
            unzip
            uv
        ]); #++ (with pkgsunstable; [
        #    gemini-cli
        #]);

    # networking = {
    #     hostName = hostName;
    #     enableIPv6 = false;
    #     networkmanager = {
    #         enable = true;
    #     };
    #     dhcpcd.wait = "background";
    #     firewall = {
    #         enable = true;
    #         allowedTCPPorts = [ 22 32400 ];
    #     };
    # };

    networking = {
        hostName = hostName;
        enableIPv6 = false;
        networkmanager.enable = false;
        interfaces.eno1.useDHCP = true;
        interfaces.eno2.useDHCP = true;

        dhcpcd.wait = "background";
        firewall = {
            enable = true;
            allowedTCPPorts = [ 22 32400 ];
        };
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

    virtualisation.docker.enableNvidia = true;
    
	# optimize store (ie: remove duplicates)
    nix.settings.auto-optimise-store = true;

    system.stateVersion = "23.11";
}
