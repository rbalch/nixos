{ inputs, ... }:

let
  inherit (inputs) nixpkgs home-manager;
in
hostname:
{ system ? "x86_64-linux"
, dir ? hostname
, modules ? []
}:

nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit inputs;
    hostName = hostname;
  };
  modules = [
    ../hosts/${dir}

    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.ryan = import ../users/ryan;
    }
  ] ++ modules;
}
