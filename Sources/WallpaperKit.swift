import AppKit
import CoreImage
import ImageIO
import UniformTypeIdentifiers

/// Come adattare un'immagine alla risoluzione di destinazione.
enum FitMode: String, CaseIterable, Identifiable {
    case fill = "Riempi"
    case fit  = "Adatta"
    var id: String { rawValue }
    var help: String {
        switch self {
        case .fill: "Ingrandisce fino a coprire tutto e ritaglia il resto"
        case .fit:  "Rientra tutta nell'inquadratura, con bande ai lati"
        }
    }
}

struct WallpaperError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

enum WallpaperKit {

    // MARK: - Caricamento

    static func load(_ url: URL) -> CGImage? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(src, 0, nil)
    }

    // MARK: - Derivazione della variante mancante

    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    /// Ricava una versione notturna plausibile da un'immagine diurna:
    /// abbassa esposizione e saturazione, raffredda i toni verso il blu e chiude i bordi.
    static func deriveDark(from image: CGImage) -> CGImage {
        let source = CIImage(cgImage: image)
        var out = source
        out = out.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.52,
            kCIInputBrightnessKey: -0.10,
            kCIInputContrastKey: 1.08,
        ])
        out = out.applyingFilter("CITemperatureAndTint", parameters: [
            "inputNeutral": CIVector(x: 6500, y: 0),
            "inputTargetNeutral": CIVector(x: 4900, y: 8),
        ])
        out = out.applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: -1.0])
        out = out.applyingFilter("CIVignette", parameters: [
            kCIInputIntensityKey: 0.85,
            kCIInputRadiusKey: 1.7,
        ])
        return ciContext.createCGImage(out, from: source.extent) ?? image
    }

    /// Ricava una versione diurna da un'immagine notturna (caso meno frequente, resa più incerta).
    static func deriveLight(from image: CGImage) -> CGImage {
        let source = CIImage(cgImage: image)
        var out = source
        out = out.applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: 1.25])
        out = out.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 1.25,
            kCIInputBrightnessKey: 0.06,
            kCIInputContrastKey: 0.96,
        ])
        out = out.applyingFilter("CITemperatureAndTint", parameters: [
            "inputNeutral": CIVector(x: 6500, y: 0),
            "inputTargetNeutral": CIVector(x: 7600, y: -6),
        ])
        return ciContext.createCGImage(out, from: source.extent) ?? image
    }

    // MARK: - Normalizzazione

    /// Porta l'immagine esattamente a `size` pixel: le due immagini di un HEIC
    /// dinamico devono avere la stessa dimensione.
    static func normalize(_ image: CGImage, to size: CGSize, mode: FitMode) -> CGImage? {
        let tw = Int(size.width.rounded()), th = Int(size.height.rounded())
        guard tw > 0, th > 0 else { return nil }

        guard let ctx = CGContext(
            data: nil, width: tw, height: th,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }

        ctx.interpolationQuality = .high
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: tw, height: th))

        let iw = CGFloat(image.width), ih = CGFloat(image.height)
        let sx = size.width / iw, sy = size.height / ih
        let scale = mode == .fill ? max(sx, sy) : min(sx, sy)
        let dw = iw * scale, dh = ih * scale

        ctx.draw(image, in: CGRect(x: (size.width - dw) / 2, y: (size.height - dh) / 2, width: dw, height: dh))
        return ctx.makeImage()
    }

    // MARK: - Scrittura dell'HEIC dinamico

    private struct AppearanceIndexes: Codable { let l: Int; let d: Int }

    /// Scrive un HEIC a due immagini con il metadato `apple_desktop:apr`,
    /// quello che dice a macOS quale usare in modalità chiara e quale in scura.
    static func writeDynamicHEIC(light: CGImage, dark: CGImage, to url: URL, quality: Double) throws {
        guard light.width == dark.width, light.height == dark.height else {
            throw WallpaperError(message: "Le due immagini devono avere la stessa dimensione.")
        }

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let base64 = try encoder.encode(AppearanceIndexes(l: 0, d: 1)).base64EncodedString()

        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.heic.identifier as CFString, 2, nil
        ) else {
            throw WallpaperError(message: "Impossibile creare il file HEIC in \(url.path).")
        }

        let metadata = CGImageMetadataCreateMutable()
        // Senza registrare il prefisso, CGImageMetadataSetTagWithPath fallisce silenziosamente.
        CGImageMetadataRegisterNamespaceForPrefix(
            metadata, "http://ns.apple.com/namespace/1.0/" as CFString, "apple_desktop" as CFString, nil
        )
        guard let tag = CGImageMetadataTagCreate(
            "http://ns.apple.com/namespace/1.0/" as CFString,
            "apple_desktop" as CFString, "apr" as CFString,
            .string, base64 as CFString
        ), CGImageMetadataSetTagWithPath(metadata, nil, "apple_desktop:apr" as CFString, tag) else {
            throw WallpaperError(message: "Impossibile scrivere il metadato apple_desktop:apr.")
        }

        let options = [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        CGImageDestinationAddImageAndMetadata(dest, light, metadata, options)  // indice 0 = chiara
        CGImageDestinationAddImage(dest, dark, options)                        // indice 1 = scura

        guard CGImageDestinationFinalize(dest) else {
            throw WallpaperError(message: "Scrittura dell'HEIC non riuscita.")
        }
    }

    // MARK: - Applicazione come sfondo

    static func setWallpaper(_ url: URL) throws {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { throw WallpaperError(message: "Nessuno schermo rilevato.") }
        for screen in screens {
            try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
        }
    }

    static var currentWallpaperURL: URL? {
        NSScreen.main.flatMap { NSWorkspace.shared.desktopImageURL(for: $0) }
    }

    /// Risoluzione in pixel reali dello schermo principale.
    static var mainScreenPixelSize: CGSize {
        guard let screen = NSScreen.main else { return CGSize(width: 2560, height: 1600) }
        let scale = screen.backingScaleFactor
        return CGSize(width: screen.frame.width * scale, height: screen.frame.height * scale)
    }
}
