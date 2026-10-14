{ pkgs, ... }:

# nix-darwin module for the managed Home Depot Mac (Apple Silicon).
#
# Determinate's installer owns the Nix daemon and /etc/nix/nix.conf, so
# nix-darwin must not manage Nix itself.
#
# The Mac is MDM-managed (Workspace ONE) with EDR. Hostname, firewall,
# FileVault, software updates, and login items belong to MDM; leave them out.
{
  nix.enable = false;

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  system.primaryUser = "GYA8FUD";
  system.stateVersion = 6;

  users.users.GYA8FUD = {
    name = "GYA8FUD";
    home = "/Users/GYA8FUD";
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [ vim ];

  # Copied into /Library/Fonts/Nix Fonts on activation. Terminals and editors
  # here ask for "MesloLGS Nerd Font" by name, as the Linux hosts do.
  fonts.packages = [ pkgs.nerd-fonts.meslo-lg ];

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "Nlsv"; # list view
    screencapture.location = "~/Pictures/Screenshots";
  };
}
