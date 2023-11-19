{ config, lib, pkgs, ... }:
let
  configThemeNormal = ./p10k-config/p10k.zsh;
in
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      nix-update = "sudo nixos-rebuild switch";
    };
    history.size = 10000;

    initExtra = ''
      [[ ! -f ${configThemeNormal} ]] || source ${configThemeNormal}
    '';

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
    
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "thefuck" "history"];
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}