import AppKit
import SwiftUI

enum Role: String {
    case light = "Chiara"
    case dark  = "Scura"
}

struct Slot {
    var image: CGImage
    var url: URL?
    /// true se l'immagine è stata ricavata automaticamente dall'altra, non fornita dall'utente.
    var isDerived: Bool

    var pixelDescription: String { "\(image.width)×\(image.height)" }
    var name: String { url?.lastPathComponent ?? (isDerived ? "generata automaticamente" : "senza nome") }
}

struct ResolutionOption: Hashable, Identifiable {
    let label: String
    /// nil = mantieni la dimensione dell'immagine sorgente.
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
            ResolutionOption(label: "Originale", size: nil),
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

    // MARK: - Sorgenti

    func load(_ url: URL, into role: Role) {
        guard let image = WallpaperKit.load(url) else {
            report("Non riesco a leggere \(url.lastPathComponent).", error: true)
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
        // Una variante generata da un'immagine appena rimossa non ha più senso.
        if light?.isDerived == true && dark == nil { light = nil }
        if dark?.isDerived == true && light == nil { dark = nil }
        refreshDerived()
        status = ""
    }

    /// Riempie il lato mancante generandolo dall'altro.
    private func refreshDerived() {
        let realLight = light.map { !$0.isDerived } ?? false
        let realDark  = dark.map { !$0.isDerived } ?? false

        if realLight && (dark == nil || dark!.isDerived) {
            dark = Slot(image: WallpaperKit.deriveDark(from: light!.image), url: nil, isDerived: true)
        } else if realDark && (light == nil || light!.isDerived) {
            light = Slot(image: WallpaperKit.deriveLight(from: dark!.image), url: nil, isDerived: true)
        }
    }

    // MARK: - Costruzione

    private func renderPair() throws -> (light: CGImage, dark: CGImage) {
        guard let light, let dark else {
            throw WallpaperError(message: "Serve almeno un'immagine.")
        }
        let target = resolution.size ?? CGSize(width: light.image.width, height: light.image.height)
        guard let l = WallpaperKit.normalize(light.image, to: target, mode: fitMode),
              let d = WallpaperKit.normalize(dark.image, to: target, mode: fitMode) else {
            throw WallpaperError(message: "Ridimensionamento non riuscito.")
        }
        return (l, d)
    }

    func save() {
        guard isReady else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.heic]
        panel.nameFieldStringValue = suggestedFileName()
        panel.message = "Salva lo sfondo dinamico (light + dark in un solo file)"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        perform("Salvato in \(url.path)") {
            let pair = try self.renderPair()
            try WallpaperKit.writeDynamicHEIC(light: pair.light, dark: pair.dark, to: url, quality: self.quality)
        }
    }

    func apply() {
        guard isReady else { return }
        let folder = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Pictures/Wallpapers", directoryHint: .isDirectory)

        perform("Sfondo applicato — cambia aspetto di sistema per vedere lo switch") {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let pair = try self.renderPair()

            // macOS non ridisegna lo sfondo se il percorso è identico a quello già attivo,
            // quindi alterno fra due nomi e ripulisco il precedente.
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
        let stem = base.map { ($0.deletingPathExtension().lastPathComponent) } ?? "Sfondo"
        return "\(stem)-dynamic.heic"
    }

    /// Esegue il lavoro pesante fuori dal main thread e riporta l'esito in interfaccia.
    private func perform(_ successMessage: String, _ work: @escaping () throws -> Void) {
        isWorking = true
        status = "Elaborazione…"
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
