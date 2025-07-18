# nixos

## Installation

### WiFi

```bash
systemctl start wpa_supplicant
wpa_cli

add_network
set_network 0 ssid ""
set_network 0 psk ""
set_network 0 key_mgmt WPA-PSK
enable_network 0
```

### Partitioning

Setup your paritions however you want. 2 drives, 1 for boot and 1 for root.

```bash
blkid # show hardware info

lsblk # see mountings
```

### Format

Going to create our 2 drives and give them labels of "boot" and "nixos".
This will make mounting, etc, easier.

```bash
mkfs.fat -F 32 -n boot /dev/...
mkfs.ext4 -L nixos /dev/...
```

### Mount

```bash
mount /dev/disk/by-label/nixos /mnt
mkdir /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
```

### Install

```bash
nixos-install --no-write-lock-file --flake github:rbalch/nixos#{machine}
```

### Update

When you have changed configs:

```bash
nixos-rebuild --flake ./nixos#{machine} switch
```

To update existing system:

```bash
nix flake update
```

After that you probably want to run update again:

```bash
sudo nixos-rebuild switch
```

## Useage

### Look at a function

```bash
nix repl '<nixpkgs>'

:e pkgs.{name}
```

### Docker

In my latest build docker and nvidia are still angry at each other. While it complains about deprecation without:

```code
virtualisation.docker.enableNvidia = true;
```

... in machines/brain-dongle/configuration.nix the docker->nvidia stuff won't work.
