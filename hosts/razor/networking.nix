{ config, pkgs, ... }:

{
    networking = {
        hostName = "razor";
        wireless.enable = true;
        networkmanager.enable = true;
    }
}