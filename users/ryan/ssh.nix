{ hostName, lib, ... }:

{
  # Personal hosts only; the work (WSL) profile does not import this file.
  programs.zsh.shellAliases.bd = "ssh bd";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        forwardAgent = false;
        hashKnownHosts = true;
        controlMaster = "auto";
        controlPath = "~/.ssh/master-%r@%h:%p";
        controlPersist = "10s";
      };
      "bd"  = {
        hostname = "10.13.37.42";
        user = "ryan";
        identityFile = "~/.ssh/zxrbzx";
      };
      "dgx" = {
        hostname = "dgx.braindongle.com";
        user = "ryan";
        identityFile = "~/.ssh/zxrbzx";
      };
      # sparq-lappy cannot accept inbound SSH, so it holds a reverse tunnel
      # open on bd's loopback port 2222. bd reaches that directly; everyone
      # else hops through bd to get to it. The tunnel is up only while the
      # WSL distro is running, and only on the home LAN.
      "sparq-lappy" = {
        hostname = "localhost";
        port = 2222;
        user = "ryan";
        identityFile = "~/.ssh/zxrbzx";
        # localhost:2222 would otherwise collide with unrelated known_hosts
        # entries for the loopback address.
        HostKeyAlias = "sparq-lappy";
      } // lib.optionalAttrs (hostName != "brain-dongle") { proxyJump = "bd"; };
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
      "huggingface" = {
        hostname = "hf.co";
        user = "git";
        identityFile = "~/.ssh/huggingface";
        identitiesOnly = true;
      };
    };

  };
}
