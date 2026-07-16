# TODO

- [ ] Verify Claude Desktop can persist sign-in through GNOME Keyring after a full SDDM logout/login on cortex. If it still reports that no system keyring is available, inspect the user Secret Service (`org.freedesktop.secrets`) and `gnome-keyring-daemon` before changing the Claude password-store backend.
