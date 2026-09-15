{ inputs, pkgs, hostName, ... }:

{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    # WSL handles boot and hardware, so import the boot-free base rather
    # than hosts/common/default.nix.
    ../common/base.nix
    ../common/optional/docker.nix
    inputs.vscode-server.nixosModules.default
  ];

  wsl.enable = true;
  # NixOS-WSL creates this user with the wheel group; docker.nix adds docker.
  wsl.defaultUser = "ryan";
  networking.hostName = hostName;
  services.vscode-server.enable = true;

  # Native CLI installers download binaries that expect a standard Linux loader.
  programs.nix-ld.enable = true;
  users.users.ryan.shell = pkgs.zsh;

  environment.systemPackages = with pkgs; [ git gnumake vim ];

  # Keep this fixed after the first install; it controls state compatibility.
  system.stateVersion = "26.11";
}
