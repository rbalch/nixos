{ config, pkgs, ... }:

{
	virtualisation.docker = {
		enable = true;
		enableOnBoot = false;
		enableNvidia = true;

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
