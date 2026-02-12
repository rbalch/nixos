{
    description = "rbalch NixOS configurations";

    nixConfig = {
        allowUnfree = true;
        experimental-features = [ "nix-command" "flakes" ];
    };

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        pkgsunstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Freshest packages
        # nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprland.url = "github:hyprwm/Hyprland";
        nixos-hardware.url = "github:NixOS/nixos-hardware";
        vscode-server.url = "github:nix-community/nixos-vscode-server";
    };

    outputs = { self, nixpkgs, pkgsunstable, home-manager, nixos-hardware, vscode-server, ... }@inputs: {
        nixosConfigurations = {
            brain-dongle = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = {
                    hostName = "brain-dongle";
                    pkgsunstable = import pkgsunstable { system = "x86_64-linux"; };
                };
                modules = [
                    ./machines/brain-dongle/configuration.nix

                    vscode-server.nixosModules.default
                    ({ config, nixpkgs, ...}: {
                        services.vscode-server.enable = true;
                    })

                    home-manager.nixosModules.home-manager
                    {
                        home-manager.useGlobalPkgs = true;
                        home-manager.useUserPackages = true;
                        home-manager.users.ryan = import ./users/ryan;
                    }
                ];
            };
            razor = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    ./machines/razor/configuration.nix

                    home-manager.nixosModules.home-manager
                    {
                        home-manager.useGlobalPkgs = true;
                        home-manager.useUserPackages = true;
                        home-manager.users.ryan = import ./users/ryan;
                    }
                ];
            };
            nix1 = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = {
                    hostName = "nix1";
                };
                modules = [
                    nixos-hardware.nixosModules.lenovo-thinkpad-x1-11th-gen
                    ./machines/x1/configuration.nix

                    home-manager.nixosModules.home-manager
                    {
                        home-manager.useGlobalPkgs = true;
                        home-manager.useUserPackages = true;
                        home-manager.users.ryan = import ./users/ryan;
                    }
                ];
            };
            cortex = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    ./machines/cortex/configuration.nix

                    home-manager.nixosModules.home-manager
                    {
                        home-manager.useGlobalPkgs = true;
                        home-manager.useUserPackages = true;
                        home-manager.users.ryan = import ./users/ryan;
                    }
                ];
            };
        };
    };

}
