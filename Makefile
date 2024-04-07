
sync-in:
	rsync -avuz /etc/nixos/configuration.nix razor/etc/nixos/configuration.nix
	rsync -avuz ~/.config/home-manager/ razor/.config/home-manager/

install:
	nixos-install --no-write-lock-file --impure --flake github:rbalch/nixos#razor

rebuild:
	sudo nixos-rebuild switch

garbage:
	nix-collect-garbage --delete-old

get-config:
	curl -OL https://raw.githubusercontent.com/rbalch/nixos/main/configuration.nix

list-historical-versions:
	nix profile history --profile /nix/var/nix/profiles/system

update:
	sudo nix flake update

cleanup:
	# delete all historical versions older than 7 days
	sudo nix profile wipe-history --older-than 7d --profile /nix/var/nix/profiles/system
	# then run garbage collection
	sudo nix store gc --debug