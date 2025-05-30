{ config, pkgs, ... }:

{
	virtualisation.docker = {
		enable = true;
		enableOnBoot = false; # false

		# Enable NVIDIA runtime using the deprecated setting as well for compatibility
		# enableNvidia = true;

		rootless = {
			enable = true;
			setSocketVariable = false; # false
			daemon.settings = {
				runtimes = {
					nvidia = {
						path = "${pkgs.nvidia-docker}/bin/nvidia-container-runtime";
					};
				};
				# Explicitly set the default runtime to use NVIDIA
				# default-runtime = "nvidia";
			};
		};
	};
	users.extraGroups.docker.members = [ "ryan" ];
}
