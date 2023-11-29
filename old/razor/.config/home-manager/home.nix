{ config, pkgs, ... }:

{

  # this allows unstable packages to be used
  # from pkgs.unstable.<package>
  nixpkgs.config = {
    allowUnfree = true;

    packageOverrides = pkgs:
    {
      unstable = import <unstable>
        {
          config = config.nixpkgs.config;
        };
    };
  };

  imports = [
    ./modules/vscode
    ./zsh.nix
    ./ssh.nix
  ];

  home.username = "ryan";
  home.homeDirectory = "/home/ryan";

  # fonts.fontconfig.enable = true;
  home.stateVersion = "23.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    dig
    fzf
    gnumake
    jq
    lastpass-cli
    # meslo-lgs-nf
    slack
    thefuck

    (pkgs.writeShellScriptBin "docker-stop" ''
      #!/bin/bash
      docker stop $(docker ps -q)
    '')

  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/ryan/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userEmail = "ryan@balch.io";
    userName = "Ryan Balch";
  };

  fonts = {
      fonts = with pkgs; [
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        font-awesome
        source-han-sans
        source-han-sans-japanese
        source-han-serif-japanese
        (nerdfonts.override { fonts = [ "Meslo" ]; })
      ];
      fontconfig = {
        enable = true;
        defaultFonts = {
          monospace = [ "Meslo LG M Regular Nerd Font Complete Mono" ];
          serif = [ "Noto Serif" "Source Han Serif" ];
          sansSerif = [ "Noto Sans" "Source Han Sans" ];
        };
      };
  };

}
