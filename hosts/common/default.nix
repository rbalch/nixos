{ config, lib, pkgs, hostName, ... }:

{
  imports = [ ./base.nix ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  services.udisks2.enable = true;

  # User account
  users.users.ryan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "input" "libvirtd" "kvm" ];
    shell = pkgs.zsh;
  };

  # Console
  console = {
    packages = [ pkgs.terminus_font ];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-i28b.psf.gz";
    useXkbConfig = true;
  };

  # Desktop-only system packages; the CLI baseline lives in base.nix
  environment.systemPackages = with pkgs; [
    bubblewrap
    imagemagick
    nvtopPackages.full
  ];

  # Printing and wireless printer discovery
  programs.system-config-printer = lib.mkIf (hostName != "brain-dongle") {
    enable = true;
  };
  services.printing = lib.mkIf (hostName != "brain-dongle") {
    enable = true;
    drivers = with pkgs; [
      cups-browsed
      cups-filters
    ];
  };
  services.avahi = lib.mkIf (hostName != "brain-dongle") {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Fonts
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      font-awesome
      nerd-fonts.meslo-lg
      roboto
      source-sans
      source-sans-pro
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
