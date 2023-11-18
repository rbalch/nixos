{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.unstable.vscode;
    userSettings = {
      "terminal.integrated.fontFamily" = "MesloLGS NF";
    };
  };
}