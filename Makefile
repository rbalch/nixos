
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

check-docker:
	docker info | grep -i runtime

restart-docker:
	sudo systemctl restart docker && systemctl --user restart docker

test-docker:
	docker run --runtime=nvidia --device nvidia.com/gpu=all nvidia/cuda:12.8.1-base-ubuntu22.04 nvidia-smi

fix-vscode:
	# patch vscode and cursor for the javascript server
	systemctl --user enable auto-fix-vscode-server.service
	systemctl --user restart auto-fix-vscode-server.service
