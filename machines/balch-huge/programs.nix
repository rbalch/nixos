{ config, lib, pkgs, ... }:

{
  zsh = {

    enable = true;
    autosuggestion.enable = true;
    shellAliases = {
      ll = "ls -lah";
      bd = "ssh bd";
    };
    history.size = 10000;

    initExtraFirst = ''
      tabs -4

      export PATH=$HOME/bin:$PATH
      export PATH=$HOME/.nix-profile/bin:$PATH
      export PATH=/run/current-system/sw/bin:$PATH
      export PATH=/nix/var/nix/profiles/default/bin:$PATH
      export PATH=/usr/local/bin:$PATH
    '';

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ../../users/ryan/configs;
        file = "p10k.zsh";
      }
    ];
    
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "thefuck" "history"];
    };

  };

  fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # direnv = {
  #   enable = true;
  #   enableZshIntegration = true;
  #   nix-direnv.enable = true;
  # };

}

# /Applications/kitty.app/Contents/MacOS:/usr/bin:/bin:/usr/sbin:/sbin:/Users/rbalch/.zsh/plugins/powerlevel10k
# /Users/rbalch/bin:/Users/rbalch/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin