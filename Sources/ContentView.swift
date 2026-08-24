import SwiftUI

struct ContentView: View {
    @StateObject private var model = WallpaperModel()

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                titleBar
                HStack(spacing: 0) {
                    stage
                    InspectorPanel(model: model)
                        .frame(width: 312)
                        .padding(.trailing, 20)
                        .padding(.vertical, 20)
                }
            }
        }
        .frame(minWidth: 1060, minHeight: 660)
    }

    /// The window has no chrome of its own, so the title sits on a strip of glass
    /// while the system keeps drawing the traffic lights on top of it.
    private var titleBar: some View {
        Text("Dynamic Wallpaper")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .overlay(alignment: .bottom) {
                Rectangle().fill(.white.opacity(0.13)).frame(height: 0.5)
            }
    }

    private var stage: some View {
        HStack(spacing: 32) {
            DesktopPreview(role: .light, slot: model.light) { model.load($0, into: .light) }
            DesktopPreview(role: .dark, slot: model.dark) { model.load($0, into: .dark) }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The loaded wallpaper, blurred, gives the glass something worth refracting.
    private var backdrop: some View {
        Group {
            if let image = model.dark?.image ?? model.light?.image {
                Color.clear.overlay {
                    Image(nsImage: NSImage(cgImage: image,
                                           size: NSSize(width: image.width, height: image.height)))
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 60, opaque: true)
                }
                .clipped()
                .overlay(Color.black.opacity(0.5))
            } else {
                LinearGradient(
                    colors: [Color(red: 0.10, green: 0.12, blue: 0.18),
                             Color(red: 0.04, green: 0.05, blue: 0.09)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
}
