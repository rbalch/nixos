{ lib, pkgs, ... }:

# Boot-free settings shared by every host, native or WSL. Native hosts get
# this through hosts/common/default.nix; WSL imports it directly because
# default.nix also enables the bootloader and desktop services.
{
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

  programs.zsh.enable = true;

  # Join each host with `sudo tailscale up` after its first rebuild.
  # State stays in /var/lib/tailscale, so later rebuilds keep the login.
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # Locale and timezone
  i18n.defaultLocale = "en_US.UTF-8";
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

  # Baseline system packages shared by every host
  environment.systemPackages = with pkgs; [
    curl
    htop
    jq
  ];
}
