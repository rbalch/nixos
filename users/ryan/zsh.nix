{ config, lib, pkgs, hostName, ... }:
let
  configThemeNormal = configs/p10k.zsh;
in
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    shellAliases = {
      ll = "ls -lah";
      # Rebuild from the checked-out repo regardless of cwd. hostName comes
      # from mkHost and always matches the flake output (nix1 included).
      nix-update = "sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/code/nixos#${hostName}";
    };
    history.size = 10000;

    initContent = ''
      [[ ! -f ${configThemeNormal} ]] || source ${configThemeNormal}
      tabs -4
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
      plugins = [ "git" "history"];
    };

  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
