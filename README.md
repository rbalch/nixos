# nixos

Flake for Ryan's NixOS machines: four native hosts plus one NixOS-WSL
distro, all on `nixpkgs-unstable` with Home Manager as a NixOS module.
The Mac (`machines/balch-huge/`) is a separate nix-darwin flake.

| Host | Directory | What it is |
|---|---|---|
| `cortex` | `hosts/cortex` | NVIDIA workstation, daily driver, Windows dual boot |
| `brain-dongle` | `hosts/brain-dongle` | NVIDIA GPU server, vscode-server |
| `nix1` | `hosts/x1` | ThinkPad X1 (11th gen) |
| `razor` | `hosts/razor` | Small laptop |
| `sparq-lappy` | `hosts/sparq-lappy` | NixOS-WSL on a Windows work laptop |

`nix1` lives in `hosts/x1`; the flake output and hostname are `nix1`.

## Day to day

Run everything from `~/code/nixos`. The Makefile is the interface; `make help`
lists every target.

```bash
make rebuild        # switch the current host (picks the output by hostname)
make diff           # build without switching, show package changes
make update-diff    # update all inputs, then diff — review before rebuilding
make cleanup        # drop system generations >7 days old, then GC
```

Cortex and brain-dongle have throttled variants (`make rebuild-cortex`,
`make rebuild-braindongle`) that keep the machine usable during big builds.

Prefer `make` over a raw `nixos-rebuild`: every rebuild target runs
`git add -AN .` first. Flakes ignore untracked files, so a new module
otherwise fails with "path does not exist".

To update a single input instead of everything:

```bash
nix flake update home-manager
make diff
```

## Installing from scratch (native)

For a WSL install, skip to [Installing on WSL](#installing-on-wsl).

Boot the NixOS installer ISO and become root (`sudo -i`).

### 1. Network

Ethernet works on its own. On the graphical ISO, use `nmtui` for Wi-Fi. On
the minimal ISO:

```bash
systemctl start wpa_supplicant
wpa_cli

add_network
set_network 0 ssid "<ssid>"
set_network 0 psk "<password>"
set_network 0 key_mgmt WPA-PSK
enable_network 0
quit
```

Check with `ping nixos.org`.

### 2. Partition

Two partitions: an EFI boot partition (~1 GB) and root (the rest). Use
whatever tool you like (`cfdisk`, `parted`, `gdisk`); set the boot
partition's type to "EFI System".

```bash
lsblk    # disks and partitions
blkid    # filesystems, labels, UUIDs
```

### 3. Format with labels

The labels matter: the committed `hardware-configuration.nix` files for
brain-dongle, nix1, and razor mount `/dev/disk/by-label/nixos` and
`/dev/disk/by-label/boot`, so a reinstall works without editing them.

```bash
mkfs.fat -F 32 -n boot /dev/<boot-partition>
mkfs.ext4 -L nixos /dev/<root-partition>
```

Razor also expects a swap partition labelled `swap`
(`mkswap -L swap /dev/<swap-partition>`). Brain-dongle and nix1 use a swap
file, which NixOS creates.

### 4. Mount

```bash
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
```

### 5. Hardware config

**Reinstalling an existing host:** nothing to do if you used the labels
above, except on cortex, whose `hardware-configuration.nix` mounts by UUID.
Update those UUIDs (from `blkid`) or switch them to labels, then push.

**A brand-new machine:** generate its hardware config and add a host.

```bash
nixos-generate-config --root /mnt
cat /mnt/etc/nixos/hardware-configuration.nix
```

On another machine (or in a clone on the installer), create
`hosts/<name>/` with that `hardware-configuration.nix` and a `default.nix`
modelled on `hosts/razor/default.nix` (smallest native host). Set
`networking.hostName` and a current `system.stateVersion`, then add
`<name> = mkHost "<name>" {};` to `nixosConfigurations` in `flake.nix`.
Prefer `by-label` devices in the hardware config. Commit and push.

### 6. Install

```bash
nixos-install --no-write-lock-file --impure --flake github:rbalch/nixos#<host>
```

`make install` runs this for razor. To install an unpushed branch, clone the
repo instead and point at it: `--flake /path/to/clone#<host>`.

At the end, `nixos-install` asks for a root password. The config gives
`ryan` no password, so set one before rebooting:

```bash
nixos-enter --root /mnt -c 'passwd ryan'
reboot
```

### 7. First boot

Log in as `ryan`, then:

```bash
mkdir -p ~/code
git clone https://github.com/rbalch/nixos.git ~/code/nixos
cd ~/code/nixos
sudo tailscale up
./install.sh        # SSH keys and ngrok config from LastPass
```

`install.sh` needs `lpass` and `jq`; razor has `lastpass-cli` installed, on
other hosts use `nix-shell -p lastpass-cli jq --run ./install.sh`. Switch the
clone's remote to SSH once the keys are in place if you want to push.

The first Home Manager run installs Claude Code, Pi, and Grok outside the
Nix store, so it needs network. If one fails, the next rebuild retries it;
`journalctl -b -u home-manager-ryan.service` shows why.

## Installing on WSL

`sparq-lappy` runs NixOS-WSL on Windows. The flake output, the Linux
hostname, and the WSL distro name all match; Windows keeps its own hostname.
The full walkthrough, including SSH access and Tailscale, is in
[docs/wsl.md](docs/wsl.md). The short version:

1. **Import the distro.** Download `nixos.wsl` from the
   [NixOS-WSL releases](https://github.com/nix-community/NixOS-WSL/releases)
   and, in PowerShell:

   ```powershell
   wsl --install --from-file .\nixos.wsl --name sparq-lappy
   ```

2. **First build, as the default `nixos` user.** Confirm `uname -m` prints
   `x86_64`, then:

   ```sh
   sudo nix-channel --update
   nix-shell -p git
   git clone https://github.com/rbalch/nixos.git /tmp/nixos
   cd /tmp/nixos
   sudo nixos-rebuild boot --flake .#sparq-lappy
   exit
   exit
   ```

   Use `boot`, not `switch`: this build changes the default user from
   `nixos` to `ryan`, and upstream warns against switching while doing so.

3. **Restart WSL so the new user takes effect.** In PowerShell:

   ```powershell
   wsl -t sparq-lappy
   wsl -d sparq-lappy --user root exit
   wsl -t sparq-lappy
   wsl -d sparq-lappy
   ```

4. **Finish as `ryan`.** `whoami` and `hostname` should print `ryan` and
   `sparq-lappy`. Then clone to `~/code/nixos`, run `sudo tailscale up`, and
   use `make rebuild-sparq-lappy` from then on.

5. **Windows side.** Install a Meslo Nerd Font in Windows Terminal for the
   prompt glyphs. Git identity for work goes in `~/.gitconfig` (Home Manager
   owns `~/.config/git/config`).

A different WSL machine follows the same pattern: copy
`hosts/sparq-lappy/default.nix` without the reverse tunnel, add a
`mkHost "<name>" { homeModule = ./users/ryan/wsl.nix; }` entry, and use that
name for the distro. WSL hosts import `hosts/common/base.nix`, never
`hosts/common/default.nix`, which carries the bootloader and native-only
settings.

## Layout

```
flake.nix               inputs and the host list
lib/mkHost.nix          wires hosts/<dir> to Home Manager's users/ryan
hosts/common/           base.nix (every host), default.nix (native hosts)
hosts/common/optional/  modules hosts opt into: docker, nvidia, hyprland, sshd, …
hosts/<host>/           per-host config and hardware-configuration.nix
users/ryan/             Home Manager: apps, CLI tools, shell, editors, bars
users/ryan/configs/     raw dotfiles mapped into ~ (Hyprland, hypridle, …)
packages/               local packages (Claude Desktop, herdr, hypr-persist)
machines/balch-huge/    the Mac's separate nix-darwin flake
install.sh              post-install secrets fetch from LastPass
```

`AGENTS.md` has the detailed rules and the reasons behind them; `TODO.md`
holds pending checks.

## Docs

- [docs/wsl.md](docs/wsl.md) — NixOS-WSL setup, SSH access, Tailscale
- [docs/docker.md](docs/docker.md) — system Docker and NVIDIA GPU checks
- [docs/brain-dongle-freezes.md](docs/brain-dongle-freezes.md) — brain-dongle freeze history and diagnosis
- [docs/grok-bot.md](docs/grok-bot.md) — Grok Bot AppImage and updates
- [docs/hypr-persist.md](docs/hypr-persist.md) — Hyprland session save and restore (hypr-persist)

## Tips

Read a package's source from a REPL:

```bash
nix repl --expr 'import <nixpkgs> {}'
:e <package>
```
