# sparq-lappy on NixOS-WSL

The flake output, Linux hostname, and WSL distro use `sparq-lappy`. Windows
can keep its hostname. `wsl -d sparq-lappy` opens a shell in that distro;
`-d` means distribution.

## Import the distro

Download the latest `nixos.wsl` from the
[NixOS-WSL releases](https://github.com/nix-community/NixOS-WSL/releases),
then name the distro so the commands below match:

```powershell
wsl --install --from-file .\nixos.wsl --name sparq-lappy
```

Older `wsl` builds without `--from-file` use
`wsl --import sparq-lappy C:\wsl\sparq-lappy .\nixos.wsl` instead.

## First build

Commit and push the changes first. These steps assume the default branch
contains them; check out the right branch after cloning if needed.

In the fresh NixOS terminal, check `uname -m`: this host requires `x86_64`.
ARM needs a different host system and a replacement for the x86-only herdr
binary. Then run as the initial `nixos` user:

```sh
sudo nix-channel --update
nix-shell -p git
git clone https://github.com/rbalch/nixos.git /tmp/nixos-sparq-lappy
cd /tmp/nixos-sparq-lappy
sudo nixos-rebuild boot --flake .#sparq-lappy
exit
exit
```

The exits leave `nix-shell` and the original shell. Use `boot` for this first
build: upstream warns against `switch` when changing the default user.

In PowerShell, run the full restart sequence:

```powershell
wsl -t sparq-lappy
wsl -d sparq-lappy --user root exit
wsl -t sparq-lappy
wsl -d sparq-lappy
```

Back in NixOS:

```sh
whoami                         # ryan
hostname                       # sparq-lappy
mkdir -p ~/code
git clone https://github.com/rbalch/nixos.git ~/code/nixos
cd ~/code/nixos
sudo tailscale up --hostname=sparq-lappy
```

If the first clone used a branch, check out that branch here too. The first
Home Manager run installs Claude Code, Pi, and Grok outside the Nix store and
needs network access. Those tools keep their own update paths. Codex and
Gemini use the same npx wrappers as the desktop hosts.

Home Manager links the shell files before running those installers. Each
installer has a 120 s limit; a failure or timeout prints a warning and later
rebuilds retry missing tools. To inspect a first-boot failure, run
`sudo journalctl -b -u home-manager-ryan.service --no-pager -n 100`.

## Shared tools

- Zsh, Powerlevel10k, autosuggestions, aliases, fzf, and direnv.
- Neovim and its settings; tmux and its settings; plain Vim.
- Herdr, Claude Code, Pi, Grok, Codex, Gemini, Node, and cliamp.
- Git with LFS, GitHub CLI, AWS CLI, Google Cloud SDK, Terraform, and SSHFS.
- Docker's system daemon, Tailscale, and the VS Code server patch service.

Docker runs inside WSL; Docker Desktop integration is not needed. Check it
with `docker info`. `make test-docker` checks NVIDIA on the GPU hosts and
does not apply here.

The config does not copy personal Git identity, SSH keys or host settings,
cloud login state, or the personal Google Cloud project. Home Manager owns
`~/.config/git/config`, so `git config --global` cannot write there; set
work Git details in `~/.gitconfig`, which Git reads afterwards:

```sh
git config --file ~/.gitconfig user.name "Your Name"
git config --file ~/.gitconfig user.email "you@work.example"
```

Install and select a Meslo Nerd Font in the Windows terminal app for the
Powerlevel10k glyphs. Linux shell settings do not set its font or clipboard
shortcuts. Neovim yanks reach the Windows clipboard through wl-clipboard,
which needs WSLg (`WAYLAND_DISPLAY` set); inside tmux, yanks go to the tmux
buffer instead.

## Tailscale

This config runs Tailscale inside WSL. Sign in once with `tailscale up`;
later rebuilds retain its state. Windows does not need Tailscale for this
Linux node. This does not give every Windows app Tailscale access.

Avoid running Tailscale on both Windows and WSL at once: upstream documents
failures when WSL traffic also passes through Windows Tailscale. If Windows
already runs it, choose which side should own the connection before signing
in here.

## Inbound SSH from the LAN

`hosts/sparq-lappy/default.nix` imports `hosts/common/optional/sshd.nix`, so
sshd runs with key-only auth and NixOS opens port 22 inside the VM. That
alone is not reachable: WSL2 defaults to NAT, so `eth0` holds a private
`172.x` address that changes on every restart and no LAN host can route to
it. Two Windows-side pieces finish the job.

### Reaching the VM

Mirrored networking is the simpler option and needs Windows 11 build
22621.2359 or newer. WSL then shares the host's real interfaces, so the
laptop's own LAN address serves port 22 with no forwarding and no IP churn.
Create `C:\Users\<you>\.wslconfig`:

```ini
[wsl2]
networkingMode=mirrored
```

Run `wsl --shutdown` afterwards. Writing `.wslconfig` and restarting WSL
need no special rights, but the firewall step below does.

Mirrored mode places WSL behind the Hyper-V firewall, whose
`DefaultInboundAction` is `Block`, so it needs its own rule; keep it scoped
to port 22 rather than opening the whole VM. **This requires local
administrator rights.** On a managed laptop where the account sits only in
`BUILTIN\Users`, this step and the `netsh portproxy` fallback are both
unavailable, and inbound LAN SSH cannot be enabled without IT. Check with
`Get-NetFirewallHyperVVMSetting -PolicyStore ActiveStore`. In an admin
PowerShell:

```powershell
New-NetFirewallHyperVRule -Name "WSL-SSH" -DisplayName "WSL SSH" `
  -Direction Inbound -VMCreatorId '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' `
  -Protocol TCP -LocalPorts 22 -Action Allow
New-NetFirewallRule -DisplayName "WSL SSH" -Direction Inbound `
  -Protocol TCP -LocalPort 22 -Action Allow
```

Mirrored mode changes networking for every WSL distro, and Docker's bridge
networks sometimes misbehave under it, so check `docker info` and a running
container after the switch. If Windows also runs its own OpenSSH server,
the two compete for port 22; move one of them.

Where mirrored mode is not usable, keep NAT and forward the port instead:

```powershell
netsh interface portproxy add v4tov4 listenport=22 listenaddress=0.0.0.0 `
  connectport=22 connectaddress=$(wsl -d sparq-lappy hostname -I).Trim()
```

The WSL address changes at every boot, so this form needs a scheduled task
that re-runs it each startup.

### Reverse tunnel (the approach in use)

Because the firewall step needs rights this account does not have, the host
dials out instead. `hosts/sparq-lappy/default.nix` runs a
`reverse-tunnel` systemd service holding an SSH connection to
brain-dongle with `-R 2222:localhost:22`, so brain-dongle's loopback port
2222 reaches this host's sshd. Outbound is allowed, so nothing inbound is
needed.

The pieces, all on the `sparq-lappy-tunnel` branch:

- `hosts/sparq-lappy/default.nix` — the tunnel service. Plain `ssh` under
  `Restart=always` rather than autossh; systemd already supervises, and
  `ServerAliveInterval`/`ServerAliveCountMax` drop a dead link in ~90 s.
  `ExitOnForwardFailure=yes` matters: without it a refused port bind still
  leaves a live connection carrying no tunnel, which systemd reads as healthy.
- `hosts/brain-dongle/default.nix` — this host's key, restricted with
  `restrict,port-forwarding,permitlisten="2222"` so it can open that one
  forward and never a shell. Deliberately not in `common/optional/sshd.nix`,
  which cortex shares.
- `hosts/common/optional/sshd.nix` — `ClientAliveInterval`, so a tunnel that
  dies with the laptop releases port 2222 instead of blocking reconnects.
- `users/ryan/ssh.nix` — a `sparq-lappy` entry. brain-dongle reaches
  `localhost:2222` directly; every other host jumps through `bd`, selected by
  a `hostName` conditional since all of them share the file.

Then `ssh sparq-lappy` from brain-dongle, cortex, nix1, or razor.

The tunnel lives only as long as the WSL distro runs, and only on the home
LAN: `bd.braindongle.com` is NXDOMAIN in public DNS, so there is no
rendezvous host from elsewhere. Reaching this host off-network needs either a
public port-forward for brain-dongle or Tailscale.

### Keeping the distro running

With no terminal open the distro is stopped and nothing listens, whichever
networking mode is in use. A logon-triggered task starts it; `conhost
--headless` keeps a console window from flashing:

```powershell
schtasks /create /tn "Start WSL sparq-lappy" /sc onlogon `
  /tr "C:\Windows\System32\conhost.exe --headless wsl.exe -d sparq-lappy -u root /run/current-system/sw/bin/true"
```

This one needs no elevation; omit `/rl highest`, which would.

Systemd keeps the VM up once started, so this fires once per boot. It still
requires a Windows login; WSL cannot run before one.

Password auth is off, so the connecting host needs the private key matching
an entry in `sshd.nix`. On corporate Wi-Fi the laptop's address is DHCP and
client isolation often blocks peer-to-peer traffic outright, which is the
case Tailscale handles instead.

## Later changes

```sh
cd ~/code/nixos
git pull
make rebuild-sparq-lappy
```

`make rebuild` and the `nix-update` alias also work once the Linux hostname
is `sparq-lappy`; the alias uses `~/code/nixos` and the explicit flake output.
Keep the state versions fixed after the first install.

The CLI module adds `~/.local/bin` to PATH. Use a fresh login after PATH
changes; `exec zsh` alone may keep old Home Manager values. For an existing
terminal, use `unset __HM_SESS_VARS_SOURCED && exec zsh`, then
`systemctl --user import-environment PATH` if user services need the new PATH.

Sources: [NixOS-WSL flakes](https://nix-community.github.io/NixOS-WSL/how-to/nix-flakes.html),
[changing the user](https://nix-community.github.io/NixOS-WSL/how-to/change-username.html),
[Tailscale on WSL](https://tailscale.com/docs/install/windows/wsl2).
