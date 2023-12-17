{ ... }:

{
    services.openssh = {
        enable = true;
        # require public key authentication for better security
        settings.PasswordAuthentication = false;
        settings.KbdInteractiveAuthentication = false;
        #settings.PermitRootLogin = "yes";
    };

    users.users.ryan.openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDs99rYjZGG6fbm7RfZxInL1cpFWlvFbE7LgpdgDIPkU/1unr3xMgQU0XfaZZhc4qYxEDO5bNsNaXLf3W636TR3yijUuo1SzBOeoEV/JRsT6uC7nCSHw9/J59ofAH2R5FC+HzJqnS7HuDn/QTFdgBWu1eiB28lENCsnQqdO6OW7wArfduzAAcII3XsDT//GGVCjP2UavOJceK7xniF1mu1UxR1asqGJGWxgamuL7se12+OZhyUfM15pHoC7QjJojO8iSQnchWDeE7ziEyoFjJFXIfziMqYwvsUfPcPsMnP0bCpMPw6Nct16muUZuqs2CRDdE0KV/FESW73HFAUp9KQbUMftm0D3d5BKliZeCpmgJczn2QKe8q8iU201npCWsl1JKbLDgj8isXAY853nZRTBFTiRy0zTmbwMHL1BO1HyfGda1GFtoeP8/OGrOHEvrY/uG5iqfnhEnQ5MBp4ow3S70SXeCvMqmkkzXK975XTLybsxu4669V+Jh4N8PFy49pU= ryan"
    ];
}
