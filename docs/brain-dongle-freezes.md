# Brain-dongle hard freezes

Brain-dongle (ASUS Pro WS W790-ACE, Xeon w7-2595X, RTX 4070 Ti SUPER) keeps
dying: every SSH session and VSCode tunnel drops at once, and the box comes
back on a fresh boot. `TODO.md` tracks the open item; this file holds the
history and the tests.

## The Great Server Paws (leading theory, 2026-10-04)

The likely culprit is the cat, not the kernel. The evidence:

- The user never power-cycled brain-dongle, yet it came back by itself after
  every death. Before 2026-10-02 the kernel had no panic-and-reboot setting,
  so a real kernel freeze would have stayed frozen. Something outside the OS
  turned it off and on again.
- logind logged ignored power-key presses: 2026-09-11 18:04, 2026-09-25
  06:14, and 2026-10-03 06:42. `HandlePowerKey = "ignore"` only stops a short
  press. Holding the button for about 4 s forces a hardware power-off, and
  the case's reset button bypasses the OS entirely. Journald only syncs to
  disk every few minutes, so a press logged just before a hard power-off is
  lost.
- Brain-dongle's deaths compared with cortex's boots:

  | Brain-dongle died | Back up | Cortex | Verdict |
  |---|---|---|---|
  | 2026-08-16 ~07:00 | 10:42 | up | bd alone |
  | 2026-08-30 ~14:00 | 17:31:47 | down, back 17:31:34 | house power outage |
  | 2026-09-08 ~17:14 | 17:36:44 | down, back 17:36:30 | house power outage |
  | 2026-09-29 after 07:00 | 07:17 | up | bd alone |
  | 2026-10-01 after 17:00 | 17:29 | up | bd alone |
  | 2026-10-02 ~18:21 | 18:24 | up | bd alone |
  | 2026-10-04 ~06:30 | ~06:30 | up | bd alone, back within about a minute |

- Brain-dongle's sshd has never logged a client timeout, so the network
  never dropped. The server end vanished. VSCode lost bd at 06:30:10 on
  2026-10-04, and netconsole puts the new kernel at about 06:30:53.
- Brain-dongle was not frozen for long: the journal's last line is the
  hourly logrotate, which only bounds the time.

**Test, started 2026-10-04:** a cover over the case's power and reset
buttons. If no death occurs for one to two weeks, the cat did it. If deaths
continue, escalate:

1. Build a reboot alert on cortex: a user timer reads bd's
   `/proc/sys/kernel/random/boot_id` over SSH every 60 s and sends a critical
   notification when it changes ("brain-dongle rebooted, down ~45 s"), plus
   one notification when bd is unreachable for 2 min and one when it
   returns.
2. Check the Anker Solix event log and UPS mode, and suspect bd's PSU (dips
   that cortex rides through).
3. Run the deliberate-panic test and the kernel steps below.

If the cover works, remove the panic sysctls and netconsole from
`hosts/brain-dongle/default.nix` and the receiver from
`hosts/cortex/default.nix`, and close the TODO item.

## History

- `last -x` shows unclean ends back to 2024 on kernels 6.6, 6.12, and 6.18.
- Four freezes from 2026-09-29 to 2026-10-02. Boots ended with no shutdown
  at 2026-10-01 17:00, 2026-10-01 18:00, 2026-10-02 18:21, and probably
  2026-10-02 20:35, about a second after the netconsole change went live.
- Each journal just stops. There is no panic, NVIDIA Xid, OOM, MCE, or EDAC
  error. Freezes happen at idle, once within 45 minutes of boot. The last
  line is often the hourly logrotate; that timing means nothing.
- Fifth freeze, 2026-10-04, after the BIOS flash and the panic sysctls. The
  local journal ends with logrotate at 06:00:16; the next boot began at
  06:30:33 with dirty filesystems. Cortex's netconsole log has nothing from
  that boot after 2026-10-03 20:46, so no panic message was sent. Pstore and
  the firmware's BERT table hold no records. The board has no BMC (the ASMB11
  card is absent), so no hardware event log exists. Nobody power-cycled it:
  the box came back by itself, as it had every time (see the Great Server
  Paws above; the earlier belief that freezes needed a power cycle was
  wrong).
- Two explanations fit. Either the hard-lockup panic fired and rebooted the
  box but wrote nothing to netconsole or pstore, or the firmware or hardware
  reset the box under the kernel. A kernel panic normally writes its log to
  pstore through ERST, and pstore was empty at boot, which favors a
  firmware or hardware reset. The deliberate-panic test below separates the
  two.
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

## Changes on 2026-10-04

- The `loglevel=4` console level kept warnings and info lines off every
  console, netconsole included: brain-dongle's journal kept kernel lines
  until 22:44 on 2026-10-03 that cortex never received. `kernel.printk` is
  now `7 4 1 7`, so everything except debug messages is sent.
- `kernel.softlockup_panic=1`: a soft lockup now panics and reboots like a
  hard lockup, and its trace goes out first.

## Deliberate-panic test

This test checks that a panic reaches both cortex and pstore. It reboots
brain-dongle, so first check that the rig user has nothing running. On
brain-dongle:

```sh
sync; echo c | sudo tee /proc/sysrq-trigger
```

The box should come back in about a minute. Then check both records:

- On cortex, `journalctl -u netconsole-receiver -n 60` should show the
  `sysrq triggered crash` trace.
- On brain-dongle, `sudo ls /var/lib/systemd/pstore/` should list a new
  dump.

If both records exist, the 2026-10-04 reset bypassed the kernel. Suspect
idle power states and power delivery: test `intel_idle.max_cstate=1` or
disable package C-states in the BIOS, then suspect the PSU. If neither
record exists, the 2026-10-04 freeze may have been a panic that left no
trace. Fix the capture path (netpoll on `atlantic`, or kdump) before
drawing conclusions.

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
   (the lockup never reached the NMI watchdog). A self-reset with no panic
   in the netconsole log points at firmware or hardware (a fatal machine
   check handled by the BIOS, the PSU, or CPU power delivery), not the
   kernel.
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
