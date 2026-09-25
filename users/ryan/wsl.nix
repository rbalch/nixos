{ pkgs, ... }:

# Work profile for NixOS-WSL. Shares the CLI tools, shell, editor, and SSH
# hosts with the desktop profile but leaves out personal apps, the cloud
# project, and Git identity.
{
  imports = [ ./cli.nix ./zsh.nix ./nvim.nix ./ssh.nix ];

  home.stateVersion = "26.11";

  home.packages = with pkgs; [ unzip zip rsync ];

  # Home Manager owns ~/.config/git/config, so `git config --global` would
  # try to write that read-only file. Set the work identity in ~/.gitconfig
  # instead: `git config --file ~/.gitconfig user.name "..."` (see docs/wsl.md).
}
