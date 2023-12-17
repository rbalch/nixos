{
    description = "rbalch NixOS configurations";

    nixConfig = {
        allowUnfree = true;
        experimental-features = [ "nix-command" "flakes" ];
    };

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        # nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nixos-hardware.url = "github:NixOS/nixos-hardware";
    };

    outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }@inputs: {
        nixosConfigurations = {
            brain-dongle = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = {
                    hostName = "brain-dongle";
                };
                modules = [
                    ./machines/brain-dongle/configuration.nix

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
        };
    };

}