
sync-in:
	rsync -avuz /etc/nixos/configuration.nix razor/etc/nixos/configuration.nix
	rsync -avuz ~/.config/home-manager/ razor/.config/home-manager/

install:
	nixos-install --no-write-lock-file --impure --flake github:rbalch/nixos#razor

garbage:
	nix-collect-garbage --delete-old

get-config:
	curl -OL https://raw.githubusercontent.com/rbalch/nixos/main/configuration.nix