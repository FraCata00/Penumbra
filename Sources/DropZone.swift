import SwiftUI
import UniformTypeIdentifiers

/// Half of the window: shows the preview edge to edge and accepts an image
/// by drag and drop or with a click.
struct DropZone: View {
    let role: Role
    let slot: Slot?
    let onPick: (URL) -> Void
    let onClear: () -> Void

    @State private var isTargeted = false
    @State private var isHovering = false

    private var accent: Color { role == .light ? .orange : .indigo }

    var body: some View {
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
        }
        .overlay(alignment: .top) { badge }
        .overlay(alignment: .center) { if slot == nil { hint } }
        .overlay {
            Rectangle()
                .strokeBorder(accent, lineWidth: isTargeted ? 4 : 0)
                .animation(.easeOut(duration: 0.15), value: isTargeted)
        }
        .contentShape(Rectangle())
        .onTapGesture { pickFile() }
        .onHover { isHovering = $0 }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            onPick(url)
            return true
        } isTargeted: { isTargeted = $0 }
    }

    // Backdrop for the empty slots: day and night hinted at, as in the app icon.
    private var emptyBackdrop: some View {
        LinearGradient(
            colors: role == .light
                ? [Color(red: 0.49, green: 0.78, blue: 0.94), Color(red: 0.13, green: 0.46, blue: 0.71)]
                : [Color(red: 0.15, green: 0.20, blue: 0.36), Color(red: 0.03, green: 0.05, blue: 0.11)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private var badge: some View {
        HStack(spacing: 6) {
            Image(systemName: slot?.isDerived == true
                  ? "wand.and.stars"
                  : (role == .light ? "sun.max.fill" : "moon.stars.fill"))
            VStack(alignment: .leading, spacing: 0) {
                Text(role.rawValue).fontWeight(.medium)
                if let slot {
                    Text(slot.isDerived ? "generated · \(slot.pixelDescription)" : "\(slot.name) · \(slot.pixelDescription)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            if slot != nil && isHovering {
                Button(action: onClear) { Image(systemName: "xmark") }
                    .buttonStyle(.plain)
                    .help("Remove")
            }
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: 260, alignment: .leading)
        .glassEffect(.regular.tint(accent.opacity(0.28)).interactive(), in: .capsule)
        .padding(.top, 14)
        .animation(.easeOut(duration: 0.15), value: isHovering)
    }

    private var hint: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.down.circle.dotted")
                .font(.system(size: 34, weight: .light))
            Text("Drop an image here\nor click to choose one")
                .font(.callout)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(22)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.message = "Choose the image for \(role.rawValue.lowercased()) mode"
        if panel.runModal() == .OK, let url = panel.url { onPick(url) }
    }
}
