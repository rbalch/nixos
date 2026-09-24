# Grok Bot

Cortex and nix1 include a `grok-bot` command and a Grok Bot app menu entry.
The desktop app works with cloud agents. It is separate from the `grok`
coding CLI.

## Install and update

Run `make rebuild` once to install the launcher. Then open Grok Bot from
the app menu or run:

```sh
grok-bot
```

On first use, the launcher fetches the current stable Linux AppImage from
Cursor's update service and checks its SHA-256 checksum. The app lives in
`~/.local/share/grok-bot`, outside the Nix store. Existing installs keep
working without a network check on each launch.
If you set `XDG_DATA_HOME`, the app uses `$XDG_DATA_HOME/grok-bot` instead.

To get a newer release:

```sh
grok-bot update
```

Quit and reopen the app after an update. Updates do not need a Nix rebuild
or a change to this repo. A failed download or checksum check leaves the
installed app in place.
The updater also keeps the prior image as `Grok_Bot.previous.AppImage`
in the same directory.

## Why the wrapper handles updates

Nix supplies the Linux runtime, Wayland flags, keyring support, app menu
entry, and browser sign-in handlers. The app's own AppImage setup creates
a menu entry that runs the binary without the NixOS runtime. That entry
takes precedence over Home Manager's working entry.

The wrapper clears `APPIMAGE` before starting Grok to prevent that menu
change. This also disables its built-in AppImage updater, so use
`grok-bot update` instead of the app's update controls. Keep the wrapper
when replacing the app.

The updater uses the same release feed as the app. That endpoint is an
upstream implementation detail, so a change to it may need a wrapper fix.
The app and its releases are not pinned by `flake.lock`.
