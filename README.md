# Dynamic Wallpaper

App macOS per creare sfondi **Light & Dark**: un solo file `.heic` che contiene
l'immagine diurna e quella notturna, e che macOS commuta da solo quando cambia
l'aspetto di sistema. Nessun daemon, nessuno script in background — lo switch
lo fa il sistema leggendo un metadato dentro il file.

![icona](Resources/AppIcon.icns)

## Come funziona

Un wallpaper dinamico di macOS è un HEIC multi-immagine con un tag XMP nel
namespace `http://ns.apple.com/namespace/1.0/`:

| chiave | valore |
|---|---|
| `apple_desktop:apr` | plist binario in base64, `{ l: 0, d: 1 }` |

`l` e `d` sono gli **indici** delle immagini dentro il file: quale usare in
modalità chiara e quale in modalità scura. L'app scrive esattamente quello.

Due dettagli che costano ore se non li sai:

- `CGImageMetadataSetTagWithPath` fallisce in silenzio (ritorna `false`, nessun
  errore) se prima non registri il prefisso con
  `CGImageMetadataRegisterNamespaceForPrefix`.
- le due immagini devono avere **la stessa identica dimensione in pixel**,
  altrimenti il file si scrive ma il risultato è imprevedibile.

## Uso

Trascina un'immagine nel riquadro *Chiara* e una in quello *Scura*, poi
**Applica**. Se ne dai una sola, l'altra variante viene generata: la notturna
abbassando esposizione e saturazione, raffreddando i toni verso il blu e
chiudendo i bordi con una vignettatura.

- **Risoluzione** — di default la risoluzione nativa in pixel del display.
- **Ritaglio** — *Riempi* ingrandisce e ritaglia, *Adatta* rientra con le bande.
- **Salva .heic…** esporta il file senza applicarlo.

Gli sfondi applicati finiscono in `~/Pictures/Wallpapers/`.

## Build

```sh
./build.sh            # produce build/Dynamic Wallpaper.app
./Tools/make-icon.sh  # rigenera l'icona (disegnata da codice)
```

Serve solo la toolchain Swift di Xcode, niente progetto `.xcodeproj`: `build.sh`
compila i sorgenti con `swiftc` e assembla il bundle `.app` a mano.

Richiede **macOS 26** (l'interfaccia usa Liquid Glass: `glassEffect`,
`GlassEffectContainer`, `.buttonStyle(.glass)`).

## Struttura

```
Sources/
  WallpaperKit.swift        # immagini, HEIC, metadato, impostazione sfondo
  WallpaperModel.swift      # stato dell'app e orchestrazione
  ContentView.swift         # finestra e barra dei controlli in vetro
  DropZone.swift            # riquadro con trascinamento e anteprima
  DynamicWallpaperApp.swift # entry point
Tools/mkicon.swift          # icona disegnata con CoreGraphics
```

## Note

macOS non ridisegna lo sfondo se il percorso del file è identico a quello già
attivo: per questo `apply()` alterna fra due nomi e cancella il precedente.
