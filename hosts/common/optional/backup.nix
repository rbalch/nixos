{ hostName, ... }:

# Nightly restic backup of ~/code and ~/brain to the UNAS. Needs unas.nix.
#
# restic, not rsync: the share drops Linux modes and cannot hold symlinks
# (see unas.nix), and a plain mirror copies deletions within a day. restic
# keeps both inside its own repo files and keeps dated snapshots.
#
# The repo password lives in /etc/restic-password, created by hand and kept
# out of git and the Nix store. Save a copy elsewhere: without it the backup
# cannot be read.
#
#   sudo install -m 600 -o root -g root /dev/stdin /etc/restic-password
#
# Restore with the wrapper, which already knows the repo and password:
#
#   sudo restic-home snapshots
#   sudo restic-home restore latest --target /tmp/restore --include /home/ryan/code/foo
{
  services.restic.backups.home = {
    repository = "/mnt/unas/backups/${hostName}";
    passwordFile = "/etc/restic-password";
    initialize = true;
    paths = [
      "/home/ryan/code"
      "/home/ryan/brain"
    ];
    exclude = [
      # Rebuildable dependency and tool caches
      "node_modules"
      ".venv"
      "venv"
      "__pycache__"
      ".pytest_cache"
      ".ruff_cache"
      ".mypy_cache"
      ".direnv"
      ".next"
      "target"
      # Model weights: ~350 GB in 2026-10, all downloadable again
      "*.safetensors"
      "*.gguf"
      "*.ckpt"
      "*.pt"
      "*.pth"
      "*.onnx"
      "ollama/models"
    ];
    extraBackupArgs = [ "--exclude-caches" ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
    timerConfig = {
      OnCalendar = "02:00";
      # Run at next boot if the box was down at 2am.
      Persistent = true;
    };
  };

  # Mount the NAS first; if that fails, the job fails up front. After a
  # boot catch-up run, wait for unas-wait (per host, may not exist).
  systemd.services.restic-backups-home = {
    requires = [ "mnt-unas.mount" ];
    after = [ "mnt-unas.mount" "unas-wait.service" ];
  };
}
