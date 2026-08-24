import AppKit
import CoreImage
import ImageIO
import UniformTypeIdentifiers

/// How a source image is fitted to the output resolution.
enum FitMode: String, CaseIterable, Identifiable {
    case fill = "Fill"
    case fit  = "Fit"
    var id: String { rawValue }
    var help: String {
        switch self {
        case .fill: "Scales up to cover the frame and crops the overflow"
        case .fit:  "Fits the whole image in, leaving bars on the sides"
        }
    }
}

struct WallpaperError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

enum WallpaperKit {

    // MARK: - Loading

    static func load(_ url: URL) -> CGImage? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(src, 0, nil)
    }

    // MARK: - Deriving the missing variant

    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    /// Derives a plausible night version from a daytime image: drops exposure and
    /// saturation, cools the tones toward blue and closes down the edges.
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

    /// Derives a daytime version from a night image — the rarer case, and a shakier result.
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

    // MARK: - Normalization

    /// Brings the image to exactly `size` pixels: both images of a dynamic HEIC
    /// must share the same dimensions.
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

    // MARK: - Writing the dynamic HEIC

    private struct AppearanceIndexes: Codable { let l: Int; let d: Int }

    /// Writes a two-image HEIC carrying the `apple_desktop:apr` metadata — the tag
    /// that tells macOS which image to use in light mode and which in dark mode.
    static func writeDynamicHEIC(light: CGImage, dark: CGImage, to url: URL, quality: Double) throws {
        guard light.width == dark.width, light.height == dark.height else {
            throw WallpaperError(message: "Both images must have the same dimensions.")
        }

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let base64 = try encoder.encode(AppearanceIndexes(l: 0, d: 1)).base64EncodedString()

        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.heic.identifier as CFString, 2, nil
        ) else {
            throw WallpaperError(message: "Could not create the HEIC file at \(url.path).")
        }

        let metadata = CGImageMetadataCreateMutable()
        // Without registering the prefix first, CGImageMetadataSetTagWithPath fails silently.
        CGImageMetadataRegisterNamespaceForPrefix(
            metadata, "http://ns.apple.com/namespace/1.0/" as CFString, "apple_desktop" as CFString, nil
        )
        guard let tag = CGImageMetadataTagCreate(
            "http://ns.apple.com/namespace/1.0/" as CFString,
            "apple_desktop" as CFString, "apr" as CFString,
            .string, base64 as CFString
        ), CGImageMetadataSetTagWithPath(metadata, nil, "apple_desktop:apr" as CFString, tag) else {
            throw WallpaperError(message: "Could not write the apple_desktop:apr metadata.")
        }

        let options = [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        CGImageDestinationAddImageAndMetadata(dest, light, metadata, options)  // index 0 = light
        CGImageDestinationAddImage(dest, dark, options)                        // index 1 = dark

        guard CGImageDestinationFinalize(dest) else {
            throw WallpaperError(message: "Writing the HEIC failed.")
        }
    }

    // MARK: - Applying as wallpaper

    static func setWallpaper(_ url: URL) throws {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { throw WallpaperError(message: "No screen detected.") }
        for screen in screens {
            try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
        }
    }

    static var currentWallpaperURL: URL? {
        NSScreen.main.flatMap { NSWorkspace.shared.desktopImageURL(for: $0) }
    }

    /// Pixel resolution of the main screen.
    static var mainScreenPixelSize: CGSize {
        guard let screen = NSScreen.main else { return CGSize(width: 2560, height: 1600) }
        let scale = screen.backingScaleFactor
        return CGSize(width: screen.frame.width * scale, height: screen.frame.height * scale)
    }
}
