{ pkgs, ... }:

let
  dockerBin = "${pkgs.docker}/bin/docker";
in {
  systemd.services.wodify-signup = {
    description = "Wodify class signup";

    serviceConfig = {
      User = "ryan";
      WorkingDirectory = "/home/ryan/code/wodify-signup";

      # Let systemd own the log file in /var/log
      StandardOutput = "append:/var/log/wodify.log";
      StandardError  = "append:/var/log/wodify.log";
    };

    # Shell script, like your cron line
    script = ''
      ${dockerBin} compose run --rm dev python /app/main.py
    '';
  };

  systemd.timers.wodify-signup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = [
        "Sun *-*-* 19:00:00"
        "Mon *-*-* 19:00:00"
        "Tue *-*-* 19:00:00"
        "Wed *-*-* 19:00:00"
        "Thu *-*-* 19:00:00"
      ];
      Persistent = true;
    };
  };
}
