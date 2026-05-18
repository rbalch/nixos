{ config, lib, pkgs, hostName, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = lib.mkDefault true;

  # Yield to interactive work — nix-daemon runs at idle CPU/IO priority,
  # so big builds (orca-slicer, kernels, etc.) can't smother the desktop.
  nix.daemonCPUSchedPolicy = "idle";
  nix.daemonIOSchedClass = "idle";

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  # User account
  programs.zsh.enable = true;
  services.udisks2.enable = true;

  users.users.ryan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "input" ];
    shell = pkgs.zsh;
  };

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    packages = [ pkgs.terminus_font ];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-i28b.psf.gz";
    useXkbConfig = true;
  };

  # Timezone
  time.timeZone = "America/New_York";

  # Sudo
  security.sudo.extraRules = [
    {
      users = [ "ryan" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # The home-manager-ryan activation runs an npx install for claude-code, which
  # needs network. Without this, the unit fires before NetworkManager finishes
  # bringing up the link at boot and exits before the rest of activation
  # (dotfile symlinks, etc.) runs.
  systemd.services.home-manager-ryan = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  environment.systemPackages = with pkgs; [
    htop
    iftop
    iperf3
  ];

  # Fonts
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      font-awesome
      nerd-fonts.meslo-lg
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "Meslo LG M Regular Nerd Font Complete Mono" ];
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
      };
    };
  };
}
