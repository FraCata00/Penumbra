Drop a daytime image and a night image, hit **Apply**, and macOS switches between
them on its own whenever the system appearance changes — no daemon, no background
script. Give it only one image and the other variant is derived for you.

### Requirements

- macOS 26 (Tahoe) — the interface uses Liquid Glass
- Apple Silicon (the build targets `arm64`)

### Install

Open the `.dmg` and drag **Penumbra** into `Applications`.

The app is ad-hoc signed and **not notarized**, so on first launch macOS says it
"could not verify that this app is free of malware". That is a signing status, not
a verdict about the app. Two ways past it:

- **Terminal** — clear the quarantine flag the download added:

  ```sh
  xattr -dr com.apple.quarantine "/Applications/Penumbra.app"
  ```

- **System Settings** — try to open the app once, let it be blocked, then go to
  *Privacy & Security*, scroll to the bottom and click **Open Anyway**.

Right-click → *Open* no longer works as a bypass on macOS 15 and later.

Building from source sidesteps this entirely: a locally built app is never
quarantined.
