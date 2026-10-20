{ config, lib, pkgs, hostName, ... }:

# Work profile for the managed Home Depot Mac. Shares the CLI tools, shell,
# editor, and SSH hosts with the desktop profile but leaves out the Wayland
# desktop, personal apps, the cloud project, and Git identity (set in
# ~/.gitconfig, as on sparq-lappy).
{
  imports = [ ./cli.nix ./ghostty.nix ./zsh.nix ./nvim.nix ./ssh.nix ./vscode.nix ./sparq-hd.nix ];

  home.stateVersion = "26.11";

  # Containers: macOS has no native Docker daemon, so Colima runs one in a
  # Lima VM and the Nix-built CLI talks to it. Unlike Docker Desktop this needs
  # no license, root helper, or MDM exception. Start it with
  # `colima start --vm-type vz --vz-rosetta`.
  home.packages = with pkgs; [ unzip zip rsync docker docker-compose docker-buildx colima ];

  # OpenRig (agent seats), run locally as this user. No `rig` service account
  # and no rig-* SSH hops: on this managed Mac it stands alone for now. The
  # installer gets longer than the default 120 s because better-sqlite3 may
  # compile; node-gyp uses Apple's clang from the Command Line Tools.
  home.activation.openrigBootstrap =
    let
      bootstrap = import ../../lib/hm-bootstrap.nix { inherit lib pkgs; timeout = 300; };
      npm = "${pkgs.nodejs_24}/bin/node ${pkgs.nodejs_24}/lib/node_modules/npm/bin/npm-cli.js";
    in
    bootstrap "rig" { path = with pkgs; [ gnumake python3 ]; } ''
      ${npm} install -g --prefix "$HOME/.local" @openrig/cli
    '';

  programs.zsh.shellAliases.nix-update =
    # Full path: sudo on macOS does not keep the user's PATH.
    "sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ${config.home.homeDirectory}/code/nixos#${hostName}";

  # The system hostname is the IT asset tag (L032NT4JFT) and stays untouched,
  # so label this machine in the shell instead: the prompt's context segment
  # and the terminal title both show `hostName`.
  programs.zsh.oh-my-zsh.extraConfig = ''
    ZSH_THEME_TERM_TITLE_IDLE="${hostName}: %~"
    ZSH_THEME_TERM_TAB_TITLE_IDLE="${hostName}: %~"
  '';

  # After p10k.zsh (sourced in zsh.nix), which hides the context segment
  # outside root and SSH. Show the label everywhere here.
  programs.zsh.initContent = lib.mkAfter ''
    unset POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_{CONTENT,VISUAL_IDENTIFIER}_EXPANSION
    typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='${hostName}'
    typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_TEMPLATE='%n@${hostName}'
    typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE='%B%n@${hostName}'
  '';
}
