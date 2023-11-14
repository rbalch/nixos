# nixos

## System Wide

To apply changes:

```bash
sudo nixos-rebuild switch
```

## Home Manager

Nixpkgs version 23.05 channel you can do initial setup:

```bash
sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-23.05.tar.gz home-manager
sudo nix-channel --update
```

Then to install it:

```bash
nix-shell '<home-manager>' -A install
```

After that to apply any changes run:

```bash
home-manager switch
```