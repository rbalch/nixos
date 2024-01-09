{ config, lib, pkgs, ... }:
let
  configThemeNormal = configs/p10k.zsh;
in
{
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    shellAliases = {
      ll = "ls -l";
      nix-update = "sudo nixos-rebuild switch";
      bd = "ssh bd";
    };
    history.size = 10000;

    initExtra = ''
      [[ ! -f ${configThemeNormal} ]] || source ${configThemeNormal}
      tabs -4
      [ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"
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