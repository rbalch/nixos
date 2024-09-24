{ config, pkgs, ... }:

{
	hardware.nvidia-container-toolkit.enable = true;

	virtualisation.docker = {
		enable = true;
		enableOnBoot = false;

		rootless = {
			enable = true;
			setSocketVariable = false;
			daemon.settings = {
				runtimes = {
					nvidia = {
						path = "${pkgs.nvidia-docker}/bin/nvidia-container-runtime";
					};
				};
			};
		};
	};
	users.extraGroups.docker.members = [ "ryan" ];
}
