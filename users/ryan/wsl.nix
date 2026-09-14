{ lib, pkgs, hostName, ... }:

{
  imports = [ ./cli.nix ./zsh.nix ./nvim.nix ];

  home.username = "ryan";
  home.homeDirectory = "/home/ryan";
  home.stateVersion = "26.05";

  # Share the shell without selecting the personal Google Cloud project.
  programs.zsh.sessionVariables = lib.mkForce {};
  programs.zsh.shellAliases.nix-update = lib.mkForce
    "sudo nixos-rebuild switch --flake /home/ryan/code/nixos#${hostName}";

  home.packages = with pkgs; [ fd ripgrep gh tmux unzip zip rsync ];
  home.file.".config/tmux/tmux.conf".source = ./configs/tmux.conf;
  home.file.".pi/agent/extensions/italic-yellow.ts".source = ./configs/pi/extensions/italic-yellow.ts;

  # Set a work identity with git config --global after the first login.
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings.core.editor = "vim";
  };
}
