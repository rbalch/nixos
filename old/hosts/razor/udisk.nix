{ config, pkgs, ...}:

{
    boot.supportedFilesystems = [ "ext4" "ntfs" ];
    services.udisks2.enable = true;
}