{ hostName, lib, ... }:

let
  # sparq-lappy is a work laptop and holds no copy of the personal key,
  # so it reuses the key it already has for the reverse tunnel.
  # hosts/brain-dongle/default.nix grants that key `pty` to allow it.
  # hd-mac is a managed work Mac with its own key (authorized in
  # hosts/common/optional/sshd.nix) rather than a copy of the personal one.
  personalKey =
    if hostName == "hd-mac"
    then "~/.ssh/hd-mac"
    else "~/.ssh/zxrbzx";
  bdIdentityFile =
    if hostName == "sparq-lappy"
    then "~/.ssh/id_ed25519"
    else personalKey;
in
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
      } // lib.optionalAttrs (hostName == "hd-mac") {
        # Apple's ssh: remember key passphrases in the login Keychain.
        addKeysToAgent = "yes";
        UseKeychain = "yes";
      };
      "bd"  = {
        hostname = "10.13.37.42";
        user = "ryan";
        identityFile = bdIdentityFile;
      };
      # Same box over Tailscale (MagicDNS name), for when off the home LAN.
      "brain-dongle" = {
        hostname = "brain-dongle";
        user = "ryan";
        identityFile = bdIdentityFile;
      };
      # Cortex over Tailscale (MagicDNS name).
      "cortex" = {
        hostname = "cortex";
        user = "ryan";
        identityFile = personalKey;
      };
      # OpenRig service account on bd (hosts/common/optional/openrig.nix).
      # `herdr --remote rig-bd` attaches to the agent seats' herdr session.
      # Uses the personal key, so this alias does not work from sparq-lappy.
      "rig-bd" = {
        hostname = "10.13.37.42";
        user = "rig";
        identityFile = "~/.ssh/zxrbzx";
      };
      # OpenRig service account on sparq-lappy, through the same reverse tunnel.
      "rig-lappy" = {
        hostname = "localhost";
        port = 2222;
        user = "rig";
        identityFile = "~/.ssh/zxrbzx";
        HostKeyAlias = "sparq-lappy";
      } // lib.optionalAttrs (hostName != "brain-dongle") { proxyJump = "bd"; };
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
      # Home Depot GitHub account. Same pattern as github.sparq; clone with
      # `git@github.hd:org/repo`.
      "github.hd" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/github-hd";
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
