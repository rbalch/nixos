{
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
        # identitiesOnly = true;
      };
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/github-eviltandem";
        identitiesOnly = true;
      };
      "huge.github" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/github-huge";
        identitiesOnly = true;
      };
    };

  };
}