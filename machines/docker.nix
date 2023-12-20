{ config, pkgs, ... }:

{
	# systemd.enableUnifiedCgroupHierarchy = false;

	virtualisation.docker = {
		enable = true;
		enableOnBoot = false;
		enableNvidia = true;
		# extraOptions = "--add-runtime nvidia=/run/current-system/sw/bin/nvidia-container-runtime";

		rootless = {
			enable = true;
			setSocketVariable = true;
            daemon.settings = {
				# group = "docker";
				# hosts = [ "fd://" ];
				runtimes = {
					nvidia = {
            			path = "${pkgs.nvidia-docker}/bin/nvidia-container-runtime";
          			};
				};
                # runtimes.nvidia = {
                #     path = "${pkgs.nvidia-docker}/bin/nvidia-container-runtime";
                # };
                # "default-runtime" = "nvidia";
				# "node-generic-resources" = [
				# 	"NVIDIA-GPU=da7eed8c-4a16-8163-b0dd-2e77663471a9"
				# ];
            };
			#daemon.settings = ''
			#	{
			#		"runtimes": { "custom": { "nvidia": { "path" = "/run/current-system/sw/bin/nvidia-container-runtime" }}}
			#	}
			#'';
		};
	};
	users.extraGroups.docker.members = [ "ryan" ];
}
