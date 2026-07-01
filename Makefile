
sync-in:
	rsync -avuz /etc/nixos/configuration.nix razor/etc/nixos/configuration.nix
	rsync -avuz ~/.config/home-manager/ razor/.config/home-manager/

install:
	nixos-install --no-write-lock-file --impure --flake github:rbalch/nixos#razor

# Flakes ignore untracked files, so new modules get "path does not exist" errors
# until staged. -AN marks them intent-to-add (visible to nix, no content staged).
rebuild:
	git add -AN .
	sudo nixos-rebuild switch --flake .#$$(hostname)

rebuild-braindongle:
	sudo nixos-rebuild switch --flake .#brain-dongle --max-jobs 4 --cores 6

rebuild-nix1:
	git add -AN .
	sudo nixos-rebuild switch --flake .#nix1

rebuild-cortex:
	sudo nixos-rebuild switch --flake .#cortex --max-jobs 2 --cores 4

garbage:
	nix-collect-garbage --delete-old

get-config:
	curl -OL https://raw.githubusercontent.com/rbalch/nixos/main/configuration.nix

list-historical-versions:
	nix profile history --profile /nix/var/nix/profiles/system

update:
	sudo nix flake update

# Preview what would build locally (cache miss) vs fetch from substituters.
# Run after `make update` to see if you're about to compile opencv/chromium/etc.
check-build:
	git add -AN .
	@echo "=== Derivations that would build locally (cache misses): ==="
	@sudo nixos-rebuild dry-build --flake .#$$(hostname) 2>&1 | awk '/will be built/,/will be fetched/' | grep -E '^\s+/nix/store' || echo "  (none — full cache hit)"
	@echo ""
	@echo "=== Derivations that would fetch from cache: ==="
	@sudo nixos-rebuild dry-build --flake .#$$(hostname) 2>&1 | awk '/will be fetched/,0' | grep -cE '^\s+/nix/store' | xargs -I{} echo "  {} paths"

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

restart-xremap:
	systemctl --user restart xremap