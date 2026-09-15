{ inputs, ... }:

let
  inherit (inputs) nixpkgs home-manager;
in
hostname:
{ system ? "x86_64-linux"
, dir ? hostname
, modules ? []
, homeModule ? ../users/ryan
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
      home-manager.backupFileExtension = "hm-backup";
      home-manager.extraSpecialArgs = {
        inherit inputs;
        hostName = hostname;
      };
      home-manager.users.ryan = import homeModule;

      # cli.nix runs three network installers (120 s cap each) on first
      # activation; Home Manager's default 5 min unit timeout would SIGKILL
      # the whole script partway through.
      systemd.services.home-manager-ryan.serviceConfig.TimeoutStartSec =
        nixpkgs.lib.mkForce "15min";
    }
  ] ++ modules;
}
