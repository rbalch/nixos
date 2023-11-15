{ config, pkgs, ... }:

{
  imports = [ ./zsh.nix ];

  home.username = "ryan";
  home.homeDirectory = "/home/ryan";

  fonts.fontconfig.enable = true;
  home.stateVersion = "23.05"; # Please read the comment before changing.
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    fzf
    git
    lastpass-cli
    meslo-lgs-nf
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

  programs.ssh = {
    enable = true;
    forwardAgent = false; # play with later - using local ssh keys on when on server
    hashKnownHosts = true;
    controlMaster = "auto";
    controlPath = "~/.ssh/master-%r@%h:%p";
    controlPersist = "10s";
    
    matchBlocks = {
      "izxrbzx"  = {
        hostname = "192.168.12.194";
        user = "ryan";
        identityFile = "~/.ssh/zxrbzx";
        identitiesOnly = true;
      };
    };

  };

}
