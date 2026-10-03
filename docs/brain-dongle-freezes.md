# Brain-dongle hard freezes

Brain-dongle (ASUS Pro WS W790-ACE, Xeon w7-2595X, RTX 4070 Ti SUPER) hard
freezes: SSH drops, the screen stops, and before 2026-10-02 it needed a power
cycle. `TODO.md` tracks the open item; this file holds the history and the
steps for the next freeze.

## History

- `last -x` shows unclean ends back to 2024 on kernels 6.6, 6.12, and 6.18.
- Four freezes from 2026-09-29 to 2026-10-02. Boots ended with no shutdown
  at 2026-10-01 17:00, 2026-10-01 18:00, 2026-10-02 18:21, and probably
  2026-10-02 20:35, about a second after the netconsole change went live.
- Each journal just stops. There is no panic, NVIDIA Xid, OOM, MCE, or EDAC
  error. Freezes happen at idle, once within 45 minutes of boot. The last
  line is often the hourly logrotate; that timing means nothing.
- The 2026-10-02 18:21 freeze killed every SSH session and the rig user's
  experiment. The rig user has no linger and no service, so nothing it runs
  survives a reboot.

## Changes on 2026-10-02

- BIOS flashed from `1401` (2024-05-30) to `2003` (2026-08-12) with EZ Flash
  3. The `.CAP` file sits in `/boot`. The versions in between, per the ASUS
  page:
  - `1502`: "improved system performance and stability"; newer CPU and
    memory init code. This is the most likely fix if one exists.
  - `1801`: Secure Boot and other CVE fixes; newer AMI code base.
  - `1904`: stability; microcode for Intel IPU 2025.4.
  - `2003`: ME firmware and security.
- The kernel still warns `Running old microcode` after the flash. The BIOS
  loads `0x2b000670` and NixOS loads `0x2b000685` early; the kernel knows a
  newer revision than nixpkgs ships.
- `hosts/brain-dongle/default.nix` sets `kernel.hardlockup_panic=1` and
  `kernel.panic=10`. A hard lockup should now panic and reboot after 10 s.
- The brain-dongle `netconsole` service broadcasts kernel messages from eno1
  to `10.13.37.255:6666`. Cortex's `netconsole-receiver` service logs them.
  The test message `netconsole-test-213132` arrived on 2026-10-02.

## After the next freeze

1. On cortex, read brain-dongle's last kernel messages:

   ```sh
   journalctl -u netconsole-receiver -n 100
   ```

2. On brain-dongle, check how the last boot ended:

   ```sh
   journalctl --list-boots | tail -3
   journalctl -b -1 -n 30
   ```

3. Note whether it rebooted by itself (panic worked) or needed a power cycle
   (the lockup never reached the NMI watchdog).
4. If freezes continue with no trace, test `intel_idle.max_cstate=1`.
5. If the freeze follows the netconsole start again, as on 2026-10-02 20:35,
   suspect netconsole and stop the `netconsole` service to test.

## Slow shutdown

Shutdown stalls 2–3 minutes after journald stops, so the local journal never
shows the cause. The shutdown log up to that point finishes in about 5 s.
"watchdog: watchdog0: watchdog did not stop!" is normal: systemd arms the
`iTCO_wdt` hardware watchdog for 10 minutes during every shutdown.

To find the cause, read `journalctl -u netconsole-receiver` on cortex after a
shutdown, or photograph the screen during the stall. Look for
`Waiting for process:` lines from systemd-shutdown.
