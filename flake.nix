/*  */{
    description = "rbalch NixOS configurations";

    nixConfig = {
        allowUnfree = true;
        experimental-features = [ "nix-command" "flakes" ];
    };

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprland.url = "github:hyprwm/Hyprland";
        nixos-hardware.url = "github:NixOS/nixos-hardware";
        vscode-server.url = "github:nix-community/nixos-vscode-server";
        xremap-flake.url = "github:xremap/nix-flake";
        tether = {
            url = "github:zackb/tether";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        claude-desktop-repo = {
            # Anthropic's apt index includes every versioned .deb path and hash.
            # `nix flake update` refreshes this lock, then our package picks the newest.
            url = "file+https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages";
            flake = false;
        };
    };

    outputs = { self, nixpkgs, home-manager, nixos-hardware, vscode-server, ... }@inputs:
    let
        mkHost = import ./lib/mkHost.nix { inherit inputs; };
    in {
        nixosConfigurations = {
            cortex = mkHost "cortex" {
                modules = [
                    inputs.tether.nixosModules.default
                    ({ ... }: {
                        programs.tether = {
                            enable = true;
                            bluetooth = {
                                enable = true;
                                adapters = [ "hci0" ];
                            };
                        };
                    })
                ];
            };

            brain-dongle = mkHost "brain-dongle" {
                modules = [
                    vscode-server.nixosModules.default
                    ({ ... }: { services.vscode-server.enable = true; })
                ];
            };

            nix1 = mkHost "nix1" {
                dir = "x1";
                modules = [
                    nixos-hardware.nixosModules.lenovo-thinkpad-x1-11th-gen
                ];
            };

            razor = mkHost "razor" {};
        };
    };
}
