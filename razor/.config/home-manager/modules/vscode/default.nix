{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.unstable.vscode;
    extensions = with pkgs.unstable.vscode-extensions; [
      bbenoist.nix
      dracula-theme.theme-dracula
      github.copilot
      ms-python.python
    ];
    userSettings = {
      "terminal.integrated.fontFamily" = "MesloLGS NF";
    };
  };
}