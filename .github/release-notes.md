Drop a daytime image and a night image, hit **Apply**, and macOS switches between
them on its own whenever the system appearance changes — no daemon, no background
script. Give it only one image and the other variant is derived for you.

### Requirements

- macOS 26 (Tahoe) — the interface uses Liquid Glass
- Apple Silicon (the build targets `arm64`)

### Install

Open the `.dmg` and drag **Dynamic Wallpaper** into `Applications`.

The app is ad-hoc signed, not notarized, so Gatekeeper stops it on first launch:
right-click the app and pick **Open**, or clear the quarantine flag with

```sh
xattr -dr com.apple.quarantine "/Applications/Dynamic Wallpaper.app"
```
