import SwiftUI
import UniformTypeIdentifiers

/// One wallpaper variant shown the way it will actually be seen: inside a mock
/// desktop with a menu bar and a Dock, so contrast problems show up immediately.
struct DesktopPreview: View {
    let role: Role
    let slot: Slot?
    let onPick: (URL) -> Void

    @State private var isTargeted = false

    private var accent: Color { role == .light ? .orange : .indigo }

    private static let dockTiles: [[Color]] = [
        [Color(red: 0.49, green: 0.83, blue: 0.99), Color(red: 0.15, green: 0.39, blue: 0.92)],
        [Color(red: 0.99, green: 0.64, blue: 0.69), Color(red: 0.88, green: 0.11, blue: 0.28)],
        [Color(red: 0.99, green: 0.83, blue: 0.30), Color(red: 0.85, green: 0.47, blue: 0.02)],
        [Color(red: 0.53, green: 0.94, blue: 0.67), Color(red: 0.09, green: 0.64, blue: 0.29)],
        [Color(red: 0.77, green: 0.71, blue: 0.99), Color(red: 0.49, green: 0.23, blue: 0.93)],
        [Color(red: 0.90, green: 0.91, blue: 0.92), Color(red: 0.61, green: 0.64, blue: 0.69)],
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            screen
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(role == .light ? "Light appearance" : "Dark appearance")
                    .font(.system(size: 12.5, weight: .semibold))
                Text("index \(role == .light ? 0 : 1)")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer(minLength: 0)
            }
            .padding(.leading, 2)
        }
        .foregroundStyle(.white)
    }

    private var screen: some View {
        ZStack {
            if let slot {
                Color.clear.overlay {
                    Image(nsImage: NSImage(cgImage: slot.image,
                                           size: NSSize(width: slot.image.width, height: slot.image.height)))
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
            } else {
                emptyBackdrop
            }

            VStack(spacing: 0) {
                menuBar
                Spacer(minLength: 0)
                dock.padding(.bottom, 8)
            }

            if slot == nil { hint }
        }
        .aspectRatio(16.0 / 10.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(isTargeted ? accent : .white.opacity(0.22),
                              lineWidth: isTargeted ? 3 : 0.5)
        }
        .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
        .contentShape(Rectangle())
        .onTapGesture { pickFile() }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            onPick(url)
            return true
        } isTargeted: { isTargeted = $0 }
        .animation(.easeOut(duration: 0.15), value: isTargeted)
    }

    private var menuBar: some View {
        HStack(spacing: 9) {
            Text("Finder").fontWeight(.bold)
            Text("File")
            Text("Edit")
            Text("View")
            Spacer(minLength: 0)
            Text("100%")
            Text("Mon 23:41")
        }
        .font(.system(size: 8.5, weight: .medium))
        .monospacedDigit()
        .padding(.horizontal, 9)
        .frame(height: 22)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
    }

    private var dock: some View {
        HStack(spacing: 5) {
            ForEach(Self.dockTiles.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(LinearGradient(colors: Self.dockTiles[i],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 24, height: 24)
            }
        }
        .padding(5)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .environment(\.colorScheme, .dark)
    }

    // Day and night hinted at, as in the app icon.
    private var emptyBackdrop: some View {
        LinearGradient(
            colors: role == .light
                ? [Color(red: 0.49, green: 0.78, blue: 0.94), Color(red: 0.13, green: 0.46, blue: 0.71)]
                : [Color(red: 0.15, green: 0.20, blue: 0.36), Color(red: 0.03, green: 0.05, blue: 0.11)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private var hint: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.dotted")
                .font(.system(size: 26, weight: .light))
            Text("Drop an image here\nor click to choose one")
                .font(.system(size: 11.5))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white.opacity(0.92))
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.message = "Choose the image for \(role.rawValue.lowercased()) mode"
        if panel.runModal() == .OK, let url = panel.url { onPick(url) }
    }
}
