{ pkgs, ... }:

{
    systemd.services.wodify-signup = {
    description = "Wodify class signup";
    serviceConfig = {
        User = "ryan";
        WorkingDirectory = "/home/ryan/code/wodify-signup";
        ExecStart = ''
        docker-compose run --rm dev python /app/main.py
        '';
        StandardOutput = "append:/var/log/wodify.log";
        StandardError = "append:/var/log/wodify.log";
    };
    };

    systemd.timers.wodify-signup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
        OnCalendar = "Sun-Thu 19:00:00";
        Persistent = true;
    };
    };
}