# Penumbra

*The penumbra is the band between full light and full shadow.*

A macOS app for building **Light & Dark** wallpapers: a single `.heic` file holding
both the daytime and the night image, which macOS switches between on its own when
the system appearance changes. No daemon, no background script — the system does
the switching by reading a metadata tag inside the file.

## Download

Grab the latest [release](../../releases): open the `.dmg` and drag
**Penumbra** into the `Applications` folder next to it. A `.zip` of the
bare app is attached too.

Requires **macOS 26** (Tahoe) on Apple Silicon.

The app is ad-hoc signed and **not notarized**, so on first launch macOS says it
"could not verify that this app is free of malware" — a signing status, not a
verdict about the app. Clear the quarantine flag the download added:

```sh
xattr -dr com.apple.quarantine "/Applications/Penumbra.app"
```

Or open it once, let macOS block it, then click **Open Anyway** at the bottom of
*System Settings → Privacy & Security*. Right-click → *Open* stopped working as a
bypass in macOS 15. Building from source avoids all of this: a locally built app
is never quarantined.

## How it works

A macOS dynamic wallpaper is a multi-image HEIC carrying an XMP tag in the
`http://ns.apple.com/namespace/1.0/` namespace:

| key | value |
|---|---|
| `apple_desktop:apr` | base64 of a binary plist, `{ l: 0, d: 1 }` |

`l` and `d` are the **indexes** of the images inside the file: which one to use in
light mode and which in dark mode. That is exactly what the app writes.

Two details that cost hours if you don't know them:

- `CGImageMetadataSetTagWithPath` fails silently — it returns `false`, raises
  nothing — unless you first register the prefix with
  `CGImageMetadataRegisterNamespaceForPrefix`. The HEIC still writes perfectly,
  just without the tag, and the wallpaper stays static.
- both images must have **exactly the same pixel dimensions**, otherwise the file
  is written but the result is unpredictable.

## Usage

Drop an image on the *Light* preview and one on the *Dark* preview, then hit
**Apply**. Each variant is shown inside a mock desktop, menu bar and Dock included,
so you can tell straight away whether the menu bar text still reads against it.
Give it only one and the other variant is derived: the night one by dropping
exposure and saturation, cooling the tones toward blue and closing down the edges
with a vignette.

- **Resolution** — defaults to the display's native pixel resolution.
- **Crop** — *Fill* scales up and crops, *Fit* fits the whole image in with bars.
- **Save .heic…** exports the file without applying it.

Applied wallpapers land in `~/Pictures/Wallpapers/`.

## Build

```sh
./build.sh                 # produces build/Penumbra.app
./Tools/make-dmg.sh 1.1.0  # packages it as a drag-to-install disk image
./Tools/make-icon.sh       # regenerates the icon (drawn from code)
```

Only Xcode's Swift toolchain is needed, no `.xcodeproj`: `build.sh` compiles the
sources with `swiftc` and assembles the `.app` bundle by hand.

The interface needs **macOS 26** for Liquid Glass (`glassEffect`,
`GlassEffectContainer`, `.buttonStyle(.glass)`).

## Layout

```
Sources/
  WallpaperKit.swift        # images, HEIC, metadata, setting the wallpaper
  WallpaperModel.swift      # app state and orchestration
  ContentView.swift         # window layout and backdrop
  DesktopPreview.swift      # one variant inside a mock desktop, and the drop target
  InspectorPanel.swift      # the glass column on the right
  PenumbraApp.swift         # entry point
Tools/mkicon.swift          # app icon drawn with CoreGraphics
```

## Notes

macOS does not redraw the desktop when the file path matches the wallpaper already
in use, which is why `apply()` alternates between two filenames and deletes the
previous one.
