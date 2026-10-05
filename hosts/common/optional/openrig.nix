{ lib, pkgs, ... }:

# Service account for OpenRig agent seats. Agents run as `rig` instead of
# `ryan`, so a seat in full-bypass mode cannot read ryan's keys or cloud
# credentials (/home/ryan is 0700), and `rig setup` can rewrite this user's
# ~/.claude and ~/.tmux.conf without fighting Home Manager. Nobody logs in as
# rig interactively; it is reached over SSH through the rig-* aliases in
# users/ryan/ssh.nix (`ssh rig-bd`, `herdr --remote rig-bd`), and the rig
# users reach each other through the aliases in users/rig.
# Imported by brain-dongle and sparq-lappy.
{
    users.users.rig = {
        isNormalUser = true;
        description = "OpenRig agent seats";
        homeMode = "700";
        # zsh is enabled system-wide in hosts/common/base.nix.
        shell = pkgs.zsh;
        # No wheel and no docker: the docker group is root-equivalent.
        openssh.authorizedKeys.keys = [
            # ryan's personal key (~/.ssh/zxrbzx), the same one
            # common/optional/sshd.nix trusts for ryan.
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDs99rYjZGG6fbm7RfZxInL1cpFWlvFbE7LgpdgDIPkU/1unr3xMgQU0XfaZZhc4qYxEDO5bNsNaXLf3W636TR3yijUuo1SzBOeoEV/JRsT6uC7nCSHw9/J59ofAH2R5FC+HzJqnS7HuDn/QTFdgBWu1eiB28lENCsnQqdO6OW7wArfduzAAcII3XsDT//GGVCjP2UavOJceK7xniF1mu1UxR1asqGJGWxgamuL7se12+OZhyUfM15pHoC7QjJojO8iSQnchWDeE7ziEyoFjJFXIfziMqYwvsUfPcPsMnP0bCpMPw6Nct16muUZuqs2CRDdE0KV/FESW73HFAUp9KQbUMftm0D3d5BKliZeCpmgJczn2QKe8q8iU201npCWsl1JKbLDgj8isXAY853nZRTBFTiRy0zTmbwMHL1BO1HyfGda1GFtoeP8/OGrOHEvrY/uG5iqfnhEnQ5MBp4ow3S70SXeCvMqmkkzXK975XTLybsxu4669V+Jh4N8PFy49pU= ryan"
            # rig-to-rig box keys for the users/rig ssh aliases. Both hosts
            # trust every rig key, each its own included.
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDkxj6RgdQycayr0rL7WVVHHHRrxT6i5YrrRD8u42+oF rig@sparq-lappy"
            # TODO: rig@brain-dongle, once `ssh-keygen -t ed25519` has run as rig on bd.
        ];
    };

    home-manager.users.rig = import ../../../users/rig;

    # Same reason as home-manager-ryan in lib/mkHost.nix: first activation runs
    # network installers.
    systemd.services.home-manager-rig.serviceConfig.TimeoutStartSec =
        lib.mkForce "15min";
}
