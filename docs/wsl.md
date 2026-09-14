# sparq-lappy on NixOS-WSL

The flake output, Linux hostname, and WSL distro use `sparq-lappy`. Windows
can keep its hostname. `wsl -d sparq-lappy` opens a shell in that distro;
`-d` means distribution.

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
cloud login state, or the personal Google Cloud project. The shared `bd`
shell alias still needs a matching SSH host or DNS name. Set work Git details
in a writable global file:

```sh
git config --file ~/.gitconfig user.name "Your Name"
git config --file ~/.gitconfig user.email "you@work.example"
```

Install and select a Meslo Nerd Font in the Windows terminal app for the
Powerlevel10k glyphs. Linux shell settings do not set its font or clipboard
shortcuts.

## Tailscale

This config runs Tailscale inside WSL. Sign in once with `tailscale up`;
later rebuilds retain its state. Windows does not need Tailscale for this
Linux node. This does not give every Windows app Tailscale access.

Avoid running Tailscale on both Windows and WSL at once: upstream documents
failures when WSL traffic also passes through Windows Tailscale. If Windows
already runs it, choose which side should own the connection before signing
in here.

## Later changes

```sh
cd ~/code/nixos
git pull
make rebuild-sparq-lappy
```

`make rebuild` also works once the Linux hostname is `sparq-lappy`.
The `nix-update` alias uses `~/code/nixos` and the explicit flake output.
Keep the state versions fixed after the first install.

The CLI module adds `~/.local/bin` to PATH. Use a fresh login after PATH
changes; `exec zsh` alone may keep old Home Manager values. For an existing
terminal, use `unset __HM_SESS_VARS_SOURCED && exec zsh`, then
`systemctl --user import-environment PATH` if user services need the new PATH.

Sources: [NixOS-WSL flakes](https://nix-community.github.io/NixOS-WSL/how-to/nix-flakes.html),
[changing the user](https://nix-community.github.io/NixOS-WSL/how-to/change-username.html),
[Tailscale on WSL](https://tailscale.com/docs/install/windows/wsl2).
