{
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
    };

    outputs = { self, nixpkgs, home-manager, nixos-hardware, vscode-server, ... }@inputs:
    let
        mkHost = import ./lib/mkHost.nix { inherit inputs; };
    in {
        nixosConfigurations = {
            cortex = mkHost "cortex" {};

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
