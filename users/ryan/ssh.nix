{ hostName, lib, ... }:

{
  # Imported by the desktop profile and by the work (WSL) profile, so the
  # same ~/.ssh/config reaches every host.
  programs.zsh.shellAliases.bd = "ssh bd";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        forwardAgent = false;
        hashKnownHosts = true;
        # Carry the truecolor hint to hosts that accept it; servers ignore
        # variables they do not list in AcceptEnv, so this is safe to send
        # everywhere. See hosts/common/optional/sshd.nix for the other end.
        sendEnv = [ "COLORTERM" ];
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
      # Work GitHub account. Separate entry so the personal key above stays
      # the default for github.com; clone with `git@github.sparq:org/repo`.
      "github.sparq" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/github-sparq";
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
