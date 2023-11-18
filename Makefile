
sync-in:
	rsync -avuz /etc/nixos/configuration.nix razor/etc/nixos/configuration.nix
	rsync -avuz ~/.config/home-manager/ razor/.config/home-manager/