{ config, pkgs, ... }:

# Inbound SSH to the managed Mac, published on bd as `sparq-hd`.
#
# Remote Login (the system sshd) belongs to IT here and would listen on every
# interface as root, so instead this user runs its own sshd, unprivileged and
# bound to loopback only, and a reverse tunnel publishes it on bd's loopback
# as port 2223 (2222 is sparq-lappy's). Same shape as sparq-lappy's
# reverse-tunnel service, but started by hand: `make sparq-hd-start`.
#
# An unprivileged sshd can only log in the user running it, which is the
# point. bd already trusts ~/.ssh/hd-mac without restrictions
# (hosts/common/optional/sshd.nix), so the -R forward needs no change there.
let
  dir = "${config.home.homeDirectory}/.ssh/sparq-hd";
  port = "2223";
  relay = "bd";
  # Apple's client, not pkgs.openssh: ~/.ssh/config sets UseKeychain
  # (users/ryan/ssh.nix), which only Apple's build understands, and the
  # Keychain is what supplies the hd-mac key's passphrase.
  ssh = "/usr/bin/ssh";

  sparq-hd = pkgs.writeShellScriptBin "sparq-hd" ''
    set -euo pipefail
    dir="${dir}"
    sock="$dir/tunnel.sock"
    pidfile="$dir/sshd.pid"

    sshd_running() { [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; }
    tunnel_up() { ${ssh} -S "$sock" -O check ${relay} 2>/dev/null; }

    case "''${1:-status}" in
      start)
        if [ ! -f "$dir/ssh_host_ed25519_key" ]; then
          ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -C sparq-hd \
            -f "$dir/ssh_host_ed25519_key"
        fi
        if sshd_running; then
          echo "sshd: already running"
        else
          # Absolute path: sshd refuses to re-exec without one.
          ${pkgs.openssh}/bin/sshd -f "$dir/sshd_config"
          echo "sshd: listening on 127.0.0.1:${port}"
        fi
        if tunnel_up; then
          echo "tunnel: already up"
        else
          # A dedicated master socket (-M -S) instead of the shared
          # ControlPath, so `stop` can close exactly this connection.
          # ControlPersist=no keeps the master tied to the forward, and
          # ExitOnForwardFailure makes a taken port an error, not a silent
          # connection with no tunnel.
          ${ssh} -fNT -M -S "$sock" \
            -o ControlPersist=no \
            -o ExitOnForwardFailure=yes \
            -o ServerAliveInterval=30 \
            -o ServerAliveCountMax=3 \
            -R ${port}:localhost:${port} \
            ${relay}
          echo "tunnel: ${relay}:localhost:${port} -> 127.0.0.1:${port}"
        fi
        ;;
      stop)
        if tunnel_up; then ${ssh} -S "$sock" -O exit ${relay}; fi
        if sshd_running; then kill "$(cat "$pidfile")"; echo "sshd: stopped"; fi
        ;;
      status)
        if sshd_running; then echo "sshd: running (pid $(cat "$pidfile"))"; else echo "sshd: stopped"; fi
        if tunnel_up; then echo "tunnel: up"; else echo "tunnel: down"; fi
        ;;
      *)
        echo "usage: sparq-hd {start|stop|status}" >&2
        exit 2
        ;;
    esac
  '';
in
{
  home.packages = [ sparq-hd ];

  home.file.".ssh/sparq-hd/sshd_config".text = ''
    ListenAddress 127.0.0.1
    Port ${port}
    HostKey ${dir}/ssh_host_ed25519_key
    PidFile ${dir}/sshd.pid
    AuthorizedKeysFile ${dir}/authorized_keys
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    # The authorized_keys below is a Home Manager symlink into the Nix store,
    # whose group-writable /nix/store fails StrictModes' path walk.
    StrictModes no
    # Reap sessions whose client vanished; see hosts/common/optional/sshd.nix.
    ClientAliveInterval 30
    ClientAliveCountMax 3
    AcceptEnv COLORTERM
    Subsystem sftp ${pkgs.openssh}/libexec/sftp-server
  '';

  # The personal and iPhone keys, as in hosts/common/optional/sshd.nix. The
  # hd-mac key is left out: this Mac has no reason to log into itself.
  home.file.".ssh/sparq-hd/authorized_keys".text = ''
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDs99rYjZGG6fbm7RfZxInL1cpFWlvFbE7LgpdgDIPkU/1unr3xMgQU0XfaZZhc4qYxEDO5bNsNaXLf3W636TR3yijUuo1SzBOeoEV/JRsT6uC7nCSHw9/J59ofAH2R5FC+HzJqnS7HuDn/QTFdgBWu1eiB28lENCsnQqdO6OW7wArfduzAAcII3XsDT//GGVCjP2UavOJceK7xniF1mu1UxR1asqGJGWxgamuL7se12+OZhyUfM15pHoC7QjJojO8iSQnchWDeE7ziEyoFjJFXIfziMqYwvsUfPcPsMnP0bCpMPw6Nct16muUZuqs2CRDdE0KV/FESW73HFAUp9KQbUMftm0D3d5BKliZeCpmgJczn2QKe8q8iU201npCWsl1JKbLDgj8isXAY853nZRTBFTiRy0zTmbwMHL1BO1HyfGda1GFtoeP8/OGrOHEvrY/uG5iqfnhEnQ5MBp4ow3S70SXeCvMqmkkzXK975XTLybsxu4669V+Jh4N8PFy49pU= ryan
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJH0nY/oKBK7russyNNb1Ya3gv5cw7qmoxDvbG82ZdpJ ryan@iphone
  '';
}
