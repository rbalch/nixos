{
    description = "NixOS configuration";

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

    outputs = { self, nixpkgs, home-manager, ... }@inputs: {
        nixosConfigurations = {
            razor = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    /etc/nixos/hardware-configuration.nix
                    ./hosts/razor
                    ./common

                    home-manager.nixosModules.home-manager
                    {
                        home-manager.useGlobalPkgs = true;
                        home-manager.useUserPackages = true;
                        home-manager.users.ryan = import ./common/users/ryan;
                    }
                ];
            };
        };
    };

}