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
        # Keep Hyprland 0.56.2 with Aquamarine 0.14. Aquamarine 0.15 can fail
        # to redraw DP-1 after DPMS wake on cortex. See TODO.md before updating.
        hyprland-pinned.url = "github:NixOS/nixpkgs/a831408e6378bc02ebf8cc09b52c96ca86f6bab4";
        hypr-persist = {
            url = "github:ngamber/hypr-persist/31836057e09b46d8d32645dbb75035f31164dd5f";
            flake = false;
        };
        nixos-hardware.url = "github:NixOS/nixos-hardware";
        nixos-wsl = {
            url = "github:nix-community/NixOS-WSL/main";
            inputs.nixpkgs.follows = "nixpkgs";
        };
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

            sparq-lappy = mkHost "sparq-lappy" {
                homeModule = ./users/ryan/wsl.nix;
            };
        };
    };
}
