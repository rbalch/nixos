#!/usr/bin/env bash
# Run a command with hypridle paused for its duration.
#
# Why: hypridle's 600s listener runs `hyprctl dispatch dpms off`, which on this
# NVIDIA card intermittently fails inside NVKMS and hard-locks the machine. A
# long unattended `nixos-rebuild` is the most likely thing to sit idle past the
# timer, and losing the box mid-activation is how you end up with a system
# generation whose bootloader was never updated. Happened 2026-07-27.
#
# Note `systemd-inhibit` does NOT help here: logind inhibitors gate suspend and
# logind's own idle action, but `hyprctl dispatch dpms off` answers to neither.
# Stopping hypridle is the only thing that actually holds the timer off.
#
# Usage: with-idle-paused.sh <command> [args...]

set -uo pipefail

if [ $# -eq 0 ]; then
    echo "usage: $(basename "$0") <command> [args...]" >&2
    exit 64
fi

resume_idle() {
    # Only relaunch if we're the one who stopped it, and only if it isn't
    # somehow already back (e.g. Hyprland was restarted by the command we ran).
    if [ "${paused:-0}" = "1" ] && ! pgrep -x hypridle >/dev/null 2>&1; then
        if [ "${managed:-0}" = "1" ]; then
            if systemctl --user start hypridle.service \
                && systemctl --user is-active --quiet hypridle.service; then
                echo "==> hypridle service resumed"
            else
                echo "==> ERROR: hypridle service failed to resume; run: systemctl --user status hypridle --no-pager" >&2
                return 1
            fi
            return
        fi

        setsid hypridle >/dev/null 2>&1 &
        idle_pid=$!

        # Give startup errors time to make the process exit before reporting
        # success. Without this check, a failed restart looks successful and
        # leaves the session with no lock or DPMS timers.
        sleep 1
        if kill -0 "$idle_pid" 2>/dev/null; then
            echo "==> hypridle resumed (pid $idle_pid)"
        else
            echo "==> ERROR: hypridle failed to resume; run: hypridle --verbose" >&2
            return 1
        fi
    fi
}

paused=0
managed=0
if pgrep -x hypridle >/dev/null 2>&1; then
    if systemctl --user is-active --quiet hypridle.service; then
        managed=1
        stop_cmd=(systemctl --user stop hypridle.service)
    else
        stop_cmd=(pkill -x hypridle)
    fi

    if "${stop_cmd[@]}" 2>/dev/null; then
        paused=1
        echo "==> hypridle paused (idle DPMS-off held off for the duration)"
    fi
fi

# Restore on normal exit and on Ctrl+C / SIGTERM alike, so an interrupted
# build never leaves the machine with no idle handling at all.
trap resume_idle EXIT INT TERM

"$@"
