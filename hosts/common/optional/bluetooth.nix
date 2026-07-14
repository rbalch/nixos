{ config, lib, pkgs, ... }:

# Bluetooth stack. Opt-in per host — import from hosts that actually have a
# radio (verify with `rfkill list` / `ls /sys/class/bluetooth`).
# Pairs via blueman-manager (GUI) or `bluetoothctl` (CLI). Audio codecs are
# handled by PipeWire, which the importing host is expected to already enable.

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;   # radio hot at boot, no manual `rfkill unblock`

    settings.General = {
      # battery % reporting for headsets/mice, plus faster reconnects
      Experimental = true;
      FastConnectable = true;
    };
  };

  # blueman-applet (tray) + blueman-manager (pairing GUI).
  # Autostart the applet from Hyprland's exec-once on hosts that want a tray icon.
  services.blueman.enable = true;
}
