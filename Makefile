.DEFAULT_GOAL := help

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

install: ## Fresh nixos-install of razor from github:rbalch/nixos
	nixos-install --no-write-lock-file --impure --flake github:rbalch/nixos#razor

# Pause hypridle for the length of a build, so a long unattended rebuild can't
# race the 600s idle timer into `hyprctl dispatch dpms off` — which on this
# NVIDIA card intermittently hard-locks the machine (2026-07-27). Restored on
# exit, failure, or Ctrl+C. systemd-inhibit deliberately NOT used: logind
# inhibitors have no authority over hyprctl.
# Deliberately the in-repo copy, not ~/.config/hypr/: the Makefile must work
# before home-manager has ever activated this file.
NO_IDLE := ./users/ryan/configs/hypr/with-idle-paused.sh

# Flakes ignore untracked files, so new modules get "path does not exist" errors
# until staged. -AN marks them intent-to-add (visible to nix, no content staged).
rebuild: ## Rebuild+switch the current host (auto-detects hostname)
	git add -AN .
	$(NO_IDLE) sudo nixos-rebuild switch --flake .#$$(hostname)

rebuild-braindongle: ## Rebuild+switch brain-dongle (throttled: -j4 -c6)
	git add -AN .
	$(NO_IDLE) sudo nixos-rebuild switch --flake .#brain-dongle --max-jobs 4 --cores 6

rebuild-nix1: ## Rebuild+switch nix1 (hostname != dir, so explicit)
	git add -AN .
	$(NO_IDLE) sudo nixos-rebuild switch --flake .#nix1

rebuild-cortex: ## Rebuild+switch cortex (throttled: -j2 -c4, keeps desktop responsive)
	git add -AN .
	$(NO_IDLE) sudo nixos-rebuild switch --flake .#cortex --max-jobs 4 --cores 6

garbage: ## Delete all old generations (nix-collect-garbage --delete-old)
	nix-collect-garbage --delete-old

get-config: ## Download configuration.nix from github (bare-install recovery)
	curl -OL https://raw.githubusercontent.com/rbalch/nixos/main/configuration.nix

list-historical-versions: ## List system generation history
	nix profile history --profile /nix/var/nix/profiles/system

update: ## Update all flake inputs (sudo nix flake update)
	sudo nix flake update

# Build new config without switching, then show package version diffs vs running system.
# Run after `make update` to see exactly what would change before committing.
diff: ## Build (no switch) and show package diffs vs running system
	git add -AN .
	@echo "=== Building new configuration (no switch)... ==="
	@$(NO_IDLE) sudo nixos-rebuild build --flake .#$$(hostname)
	@echo ""
	@echo "=== Package changes vs current system: ==="
	@nix store diff-closures /run/current-system ./result

update-diff: ## Update flake inputs then show the diff
	sudo nix flake update
	$(MAKE) diff

# Evaluation only: lists derivations that would be BUILT vs FETCHED. Builds nothing,
# fetches nothing, does not touch flake.lock or the store. Package names encode versions,
# so this shows what would change + rough download size without doing anything.
# For a precise pkg-version/size diff you must realise the closure (use `make diff`).
dry: ## Preview what would build/fetch — evaluation only, nothing built or changed
	@echo "=== Dry run (evaluation only — nothing built, fetched, or changed)... ==="
	@nixos-rebuild dry-build --flake .#$$(hostname)

# Preview what would build locally (cache miss) vs fetch from substituters.
# Run after `make update` to see if you're about to compile opencv/chromium/etc.
check-build: ## Preview cache misses (what would build locally vs fetch)
	git add -AN .
	@echo "=== Derivations that would build locally (cache misses): ==="
	@sudo nixos-rebuild dry-build --flake .#$$(hostname) 2>&1 | awk '/will be built/,/will be fetched/' | grep -E '^\s+/nix/store' || echo "  (none — full cache hit)"
	@echo ""
	@echo "=== Derivations that would fetch from cache: ==="
	@sudo nixos-rebuild dry-build --flake .#$$(hostname) 2>&1 | awk '/will be fetched/,0' | grep -cE '^\s+/nix/store' | xargs -I{} echo "  {} paths"

cleanup: ## Wipe system generations >7d old, then garbage-collect the store
	# delete all historical versions older than 7 days
	sudo nix profile wipe-history --older-than 7d --profile /nix/var/nix/profiles/system
	# then run garbage collection
	sudo nix store gc --debug

check-docker: ## Show configured Docker runtimes
	docker info | grep -i runtime

restart-docker: ## Restart both system and user Docker daemons
	sudo systemctl restart docker && systemctl --user restart docker

test-docker: ## Verify NVIDIA CDI runtime (runs nvidia-smi in a container)
	docker run --runtime=nvidia --device nvidia.com/gpu=all nvidia/cuda:12.8.1-base-ubuntu22.04 nvidia-smi

fix-vscode: ## Re-patch vscode-server for the js language server (brain-dongle)
	# patch vscode and cursor for the javascript server
	systemctl --user enable auto-fix-vscode-server.service
	systemctl --user restart auto-fix-vscode-server.service

restart-xremap: ## Restart the xremap user service (fixes hot-plug grab issues)
	systemctl --user restart xremap

kill-share-picker: ## Kill an orphaned Hyprland screen-share picker ("Select what to share")
	pkill -f hyprland-share-picker && echo "share picker killed" || echo "no share picker running"

camera-list-controls: ## List all v4l2 camera controls
	v4l2-ctl --list-ctrls

camera-lighten: ## Brighten the webcam (brightness/backlight/gain up)
	v4l2-ctl --set-ctrl=brightness=180 --set-ctrl=backlight_compensation=1 --set-ctrl=gain=50

camera-reset: ## Reset the webcam controls to defaults
	v4l2-ctl --set-ctrl=brightness=128 --set-ctrl=backlight_compensation=0 --set-ctrl=gain=0

check-kernel-bump: ## Diff current system vs latest profile (spot kernel/driver bumps)
	nix store diff-closures /run/current-system /nix/var/nix/profiles/system

update-claude-desktop: ## Fetch the latest version of claude desktop
	nix flake lock --update-input claude-desktop-repo

.PHONY: help sync-in install rebuild rebuild-braindongle rebuild-nix1 rebuild-cortex \
	garbage get-config list-historical-versions update diff update-diff dry check-build \
	cleanup check-docker restart-docker test-docker fix-vscode restart-xremap \
	kill-share-picker camera-list-controls camera-lighten camera-reset check-kernel-bump
