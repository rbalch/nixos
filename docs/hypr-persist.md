# Hyprland session restore

`hypr-persist` starts with Hyprland on native hosts. It saves open windows
every two minutes, saves again when it exits, and restores the last session
on the next login. On a fresh install, Code and Chrome still open on workspace
1. Once a saved session exists, the restore replaces that startup pair.

Save a named snapshot before a risky change:

```sh
hypr-persist save before-reboot
```

After login, check and restore it with:

```sh
hypr-persist list
hypr-persist restore before-reboot
```

The power menu saves `before-exit` before Logout, Reboot, and Shutdown. This
file is a fallback if the daemon's automatic `last` snapshot caught only part
of shutdown. Files live in `~/.local/share/hypr-persist/sessions/` as TOML.
The daemon starts only with Hyprland; run `hypr-persist status` in a session
to check it.

Restore reopens apps and puts their windows on saved workspaces. It restores
floating size and position. Layout reconstruction is off because the current
centered master layout is not supported by hypr-persist. Apps must restore
their own state, such as browser tabs or editor files. Terminal processes do
not resume; a saved working directory may reopen when it can be found.

After the first rebuild, save the current desktop before logging out:

```sh
hypr-persist save
```

Then log out and back in to start the daemon and restore that snapshot. A
Home Manager switch during an open session installs it but does not start it.
Run a named `restore` only when needed: it can open a second copy of windows
that are already live.
