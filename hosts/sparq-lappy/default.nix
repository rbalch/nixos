{ inputs, pkgs, hostName, ... }:

{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ../common/optional/docker.nix
    inputs.vscode-server.nixosModules.default
  ];

  wsl.enable = true;
  wsl.defaultUser = "ryan";
  networking.hostName = hostName;
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
  services.vscode-server.enable = true;

  # WSL handles boot and hardware. Do not import the desktop host defaults.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;
  nix.daemonCPUSchedPolicy = "idle";
  nix.daemonIOSchedClass = "idle";
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  programs.zsh.enable = true;
  # Native CLI installers download binaries that expect a standard Linux loader.
  programs.nix-ld.enable = true;
  users.users.ryan.shell = pkgs.zsh;
  security.sudo.wheelNeedsPassword = false;

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/New_York";
  environment.systemPackages = with pkgs; [ curl git gnumake htop jq vim ];

  # Keep this fixed after the first install; it controls state compatibility.
  system.stateVersion = "26.05";
}
