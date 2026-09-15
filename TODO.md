# TODO

- [ ] Before the next Hyprland update, check whether Aquamarine has fixed NVIDIA DPMS wake. Native hosts take Hyprland 0.56.2 and Aquamarine 0.14 from the pinned nixpkgs revision `a831408e6378bc02ebf8cc09b52c96ca86f6bab4`. Test several long idle wakes on cortex before removing the pin.
- [ ] After rebuilding cortex, test sharing a Chrome window in Zoom. Confirm that XDPH no longer logs `Incompatible formats, renegotiate stream` followed by `tried scheduling on already scheduled cb`. Drop the local XDPH patches once the pinned portal includes upstream commits `688feb3d` and `59d429bf`.
- [ ] Verify Claude Desktop can persist sign-in through GNOME Keyring after a full SDDM logout/login on cortex. If it still reports that no system keyring is available, inspect the user Secret Service (`org.freedesktop.secrets`) and `gnome-keyring-daemon` before changing the Claude password-store backend.
