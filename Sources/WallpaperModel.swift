import AppKit
import SwiftUI

enum Role: String {
    case light = "Light"
    case dark  = "Dark"
}

struct Slot {
    var image: CGImage
    var url: URL?
    /// True when this image was derived from the other one rather than supplied by the user.
    var isDerived: Bool

    var pixelDescription: String { "\(image.width)×\(image.height)" }
    var name: String { url?.lastPathComponent ?? (isDerived ? "generated automatically" : "untitled") }
}

struct ResolutionOption: Hashable, Identifiable {
    let label: String
    /// nil = keep the source image's own dimensions.
    let size: CGSize?
    var id: String { label }
}

@MainActor
final class WallpaperModel: ObservableObject {

    @Published var light: Slot?
    @Published var dark: Slot?
    @Published var fitMode: FitMode = .fill
    @Published var quality: Double = 0.92
    @Published var resolution: ResolutionOption
    @Published var status: String = ""
    @Published var isError = false
    @Published var isWorking = false

    let resolutionOptions: [ResolutionOption]

    init() {
        let native = WallpaperKit.mainScreenPixelSize
        var options: [ResolutionOption] = [
            ResolutionOption(label: "Display (\(Int(native.width))×\(Int(native.height)))", size: native),
            ResolutionOption(label: "Original", size: nil),
        ]
        for preset in [(1920, 1200), (2560, 1600), (3456, 2234), (3840, 2160), (5120, 2880)] {
            let size = CGSize(width: preset.0, height: preset.1)
            guard size != native else { continue }
            options.append(ResolutionOption(label: "\(preset.0)×\(preset.1)", size: size))
        }
        resolutionOptions = options
        resolution = options[0]
    }

    var isReady: Bool { light != nil && dark != nil }

    // MARK: - Sources

    func load(_ url: URL, into role: Role) {
        guard let image = WallpaperKit.load(url) else {
            report("Could not read \(url.lastPathComponent).", error: true)
            return
        }
        let slot = Slot(image: image, url: url, isDerived: false)
        switch role {
        case .light: light = slot
        case .dark:  dark = slot
        }
        refreshDerived()
        report("\(role.rawValue): \(url.lastPathComponent) — \(image.width)×\(image.height)")
    }

    func clear(_ role: Role) {
        switch role {
        case .light: light = nil
        case .dark:  dark = nil
        }
        // A variant derived from an image that was just removed no longer means anything.
        if light?.isDerived == true && dark == nil { light = nil }
        if dark?.isDerived == true && light == nil { dark = nil }
        refreshDerived()
        status = ""
    }

    /// Fills in the missing side by deriving it from the other one.
    private func refreshDerived() {
        let realLight = light.map { !$0.isDerived } ?? false
        let realDark  = dark.map { !$0.isDerived } ?? false

        if realLight && (dark == nil || dark!.isDerived) {
            dark = Slot(image: WallpaperKit.deriveDark(from: light!.image), url: nil, isDerived: true)
        } else if realDark && (light == nil || light!.isDerived) {
            light = Slot(image: WallpaperKit.deriveLight(from: dark!.image), url: nil, isDerived: true)
        }
    }

    // MARK: - Building

    private func renderPair() throws -> (light: CGImage, dark: CGImage) {
        guard let light, let dark else {
            throw WallpaperError(message: "At least one image is required.")
        }
        let target = resolution.size ?? CGSize(width: light.image.width, height: light.image.height)
        guard let l = WallpaperKit.normalize(light.image, to: target, mode: fitMode),
              let d = WallpaperKit.normalize(dark.image, to: target, mode: fitMode) else {
            throw WallpaperError(message: "Resizing failed.")
        }
        return (l, d)
    }

    func save() {
        guard isReady else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.heic]
        panel.nameFieldStringValue = suggestedFileName()
        panel.message = "Save the dynamic wallpaper (light + dark in a single file)"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        perform("Saved to \(url.path)") {
            let pair = try self.renderPair()
            try WallpaperKit.writeDynamicHEIC(light: pair.light, dark: pair.dark, to: url, quality: self.quality)
        }
    }

    func apply() {
        guard isReady else { return }
        let folder = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Pictures/Wallpapers", directoryHint: .isDirectory)

        perform("Wallpaper applied — switch the system appearance to see it change") {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let pair = try self.renderPair()

            // macOS does not redraw the desktop when the path matches the wallpaper already
            // in use, so alternate between two names and clean up the previous one.
            let stem = (self.suggestedFileName() as NSString).deletingPathExtension
            let primary = folder.appending(path: "\(stem).heic")
            let current = WallpaperKit.currentWallpaperURL?.standardizedFileURL
            let target = (current == primary.standardizedFileURL)
                ? folder.appending(path: "\(stem)-2.heic")
                : primary

            try WallpaperKit.writeDynamicHEIC(light: pair.light, dark: pair.dark, to: target, quality: self.quality)
            try WallpaperKit.setWallpaper(target)

            let stale = folder.appending(path: target == primary ? "\(stem)-2.heic" : "\(stem).heic")
            try? FileManager.default.removeItem(at: stale)
        }
    }

    private func suggestedFileName() -> String {
        let base = light?.url ?? dark?.url
        let stem = base.map { ($0.deletingPathExtension().lastPathComponent) } ?? "Wallpaper"
        return "\(stem)-dynamic.heic"
    }

    /// Runs the heavy work off the main thread and reports the outcome to the UI.
    private func perform(_ successMessage: String, _ work: @escaping () throws -> Void) {
        isWorking = true
        status = "Working…"
        isError = false
        Task.detached(priority: .userInitiated) {
            do {
                try work()
                await MainActor.run { self.report(successMessage); self.isWorking = false }
            } catch {
                await MainActor.run { self.report(error.localizedDescription, error: true); self.isWorking = false }
            }
        }
    }

    private func report(_ message: String, error: Bool = false) {
        status = message
        isError = error
    }
}
