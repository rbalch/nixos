{
    description = "rbalch NixOS configurations";

    nixConfig = {
        allowUnfree = true;
        experimental-features = [ "nix-command" "flakes" ];
    };

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nixos-hardware.url = "github:NixOS/nixos-hardware";
    };

    outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }@inputs: {
        nixosConfigurations = {
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
            x1 = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
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