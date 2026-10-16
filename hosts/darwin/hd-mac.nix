{ self, pkgs, ... }:

# nix-darwin module for a managed, Apple Silicon work Mac.
#
# Two constraints shape everything here:
#
#  1. Determinate's installer owns the Nix daemon and /etc/nix/nix.conf, so
#     nix-darwin must not manage Nix itself (nix.enable = false).
#  2. The Mac is MDM-managed (Workspace ONE) and runs EDR. IT owns the
#     hostname, firewall, FileVault, software updates, screen saver and energy
#     settings, menu bar, AirDrop, iCloud, Siri, and notifications. Those are
#     deliberately absent: a declarative config that fights its MDM loses, and
#     the hostname doubles as the asset tag. Everything below is territory a
#     user is allowed to own.
{
  # ── Nix ────────────────────────────────────────────────────────────────────
  nix.enable = false;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # ms-python.python bundles debugpy, whose check phase fails on this Mac:
  # test_lldb_command needs lldb to attach to a process, which the macOS
  # build sandbox (and the EDR) do not allow. The other 965 tests pass, so
  # skip the suite rather than lose the extension. Home Manager uses these
  # pkgs (useGlobalPkgs), so the override reaches the VS Code extension.
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyFinal: pyPrev: {
          debugpy = pyPrev.debugpy.overridePythonAttrs { doCheck = false; };
        })
      ];
    })
  ];

  # Makes `darwin-version` report the exact commit this system was built from.
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.primaryUser = "GYA8FUD";
  system.stateVersion = 6;

  users.users.GYA8FUD = {
    name = "GYA8FUD";
    home = "/Users/GYA8FUD";
  };

  # ── Shell, fonts, system packages ──────────────────────────────────────────
  programs.zsh.enable = true;
  environment.systemPackages = with pkgs; [
    vim
    # Offline speech-to-text. The Linux hosts patch it for a vLLM endpoint;
    # add that override here if the Mac needs it.
    handy
  ];

  # Copied into /Library/Fonts/Nix Fonts on activation. Terminals and editors
  # ask for "MesloLGS Nerd Font" by name, as the Linux hosts do.
  fonts.packages = [ pkgs.nerd-fonts.meslo-lg ];

  # ── Keyboard ───────────────────────────────────────────────────────────────
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system.defaults.NSGlobalDomain = {
    # Fast key repeat, and repeat instead of the accent popup on held keys.
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
    ApplePressAndHoldEnabled = false;

    # Stop macOS from rewriting what is typed into editors and terminals.
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;

    # Save and print dialogs open expanded; show every file extension.
    NSNavPanelExpandedStateForSaveMode = true;
    NSNavPanelExpandedStateForSaveMode2 = true;
    PMPrintingExpandedStateForPrint = true;
    PMPrintingExpandedStateForPrint2 = true;
    AppleShowAllExtensions = true;

    # Follow the time of day instead of pinning light or dark.
    AppleInterfaceStyleSwitchesAutomatically = true;
  };

  # ── Trackpad ───────────────────────────────────────────────────────────────
  system.defaults.trackpad = {
    Clicking = true; # tap to click
    TrackpadThreeFingerDrag = true;
  };

  # ── Dock ───────────────────────────────────────────────────────────────────
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.0;
    autohide-time-modifier = 0.2;
    show-recents = false;
    mru-spaces = false; # keep Spaces in the order they were made
    minimize-to-application = true;
    mineffect = "scale";
    tilesize = 48;
  };

  # ── Finder ─────────────────────────────────────────────────────────────────
  system.defaults.finder = {
    AppleShowAllExtensions = true;
    FXPreferredViewStyle = "Nlsv"; # list view
    FXDefaultSearchScope = "SCcf"; # search the current folder, not the Mac
    FXEnableExtensionChangeWarning = false;
    ShowPathbar = true;
    ShowStatusBar = true;
    _FXShowPosixPathInTitle = true;
    _FXSortFoldersFirst = true;
  };

  # ── Screenshots ────────────────────────────────────────────────────────────
  system.defaults.screencapture = {
    location = "~/Pictures/Screenshots";
    type = "png";
    disable-shadow = true;
  };

  # ── Gatekeeper ─────────────────────────────────────────────────────────────
  # Keep the "downloaded from the internet" prompt; it is a policy IT set.
  system.defaults.LaunchServices.LSQuarantine = true;
}
