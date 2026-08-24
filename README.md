# Dynamic Wallpaper

A macOS app for building **Light & Dark** wallpapers: a single `.heic` file holding
both the daytime and the night image, which macOS switches between on its own when
the system appearance changes. No daemon, no background script — the system does
the switching by reading a metadata tag inside the file.

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

Drop an image on the *Light* slot and one on the *Dark* slot, then hit **Apply**.
Give it only one and the other variant is derived: the night one by dropping
exposure and saturation, cooling the tones toward blue and closing down the edges
with a vignette.

- **Resolution** — defaults to the display's native pixel resolution.
- **Crop** — *Fill* scales up and crops, *Fit* fits the whole image in with bars.
- **Save .heic…** exports the file without applying it.

Applied wallpapers land in `~/Pictures/Wallpapers/`.

## Build

```sh
./build.sh            # produces build/Dynamic Wallpaper.app
./Tools/make-icon.sh  # regenerates the icon (drawn from code)
```

Only Xcode's Swift toolchain is needed, no `.xcodeproj`: `build.sh` compiles the
sources with `swiftc` and assembles the `.app` bundle by hand.

Requires **macOS 26** — the interface uses Liquid Glass (`glassEffect`,
`GlassEffectContainer`, `.buttonStyle(.glass)`).

## Layout

```
Sources/
  WallpaperKit.swift        # images, HEIC, metadata, setting the wallpaper
  WallpaperModel.swift      # app state and orchestration
  ContentView.swift         # window and the glass control bar
  DropZone.swift            # drag-and-drop slot with preview
  DynamicWallpaperApp.swift # entry point
Tools/mkicon.swift          # app icon drawn with CoreGraphics
```

## Notes

macOS does not redraw the desktop when the file path matches the wallpaper already
in use, which is why `apply()` alternates between two filenames and deletes the
previous one.
