{ config, pkgs, lib, home-manager, ... }:

let
    user = "rbalch";
in
{
    users.users.${user} = {
        name = "${user}";
        home = "/Users/${user}";
        isHidden = false;
        shell = pkgs.zsh;
    };

    home-manager = {
        useGlobalPkgs = true;
        # useUserPackages = true;

        users.${user} = {pkgs, config, lib, ...}: {
            home.packages = with pkgs; [
                lastpass-cli
                thefuck
            ];

            home = {
                stateVersion = "23.11";
            };

            programs = {} // import ./programs.nix { inherit config pkgs lib; };

        };
    };

}