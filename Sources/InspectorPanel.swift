import SwiftUI

/// Fixed glass column on the right: sources, output settings, destination, actions.
struct InspectorPanel: View {
    @ObservedObject var model: WallpaperModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            section("Sources") {
                sourceRow(.light, model.light)
                sourceRow(.dark, model.dark)
            }

            hairline

            section("Output") {
                row("Resolution") {
                    Picker("", selection: $model.resolution) {
                        ForEach(model.resolutionOptions) { Text($0.label).tag($0) }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 150)
                }
                row("Crop") {
                    Picker("", selection: $model.fitMode) {
                        ForEach(FitMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                    .help(model.fitMode.help)
                }
                row("Quality") {
                    HStack(spacing: 8) {
                        Slider(value: $model.quality, in: 0.4...1.0)
                        Text(String(format: "%.2f", model.quality))
                            .font(.system(size: 11))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(width: 150)
                }
            }

            hairline

            section("Destination") {
                Text("~/Pictures/Wallpapers/")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer(minLength: 8)

            if !model.status.isEmpty || model.isWorking { statusLine }

            VStack(spacing: 8) {
                Button { model.save() } label: {
                    Text("Save .heic…").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)

                Button { model.apply() } label: {
                    Text("Apply").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .keyboardShortcut(.defaultAction)
            }
            .controlSize(.large)
            .disabled(!model.isReady || model.isWorking)
        }
        .foregroundStyle(.white)
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    // MARK: - Pieces

    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 9.5, weight: .semibold))
                .kerning(0.7)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.5))
            content()
        }
    }

    private func row<C: View>(_ key: String, @ViewBuilder content: () -> C) -> some View {
        HStack(spacing: 10) {
            Text(key)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.72))
            Spacer(minLength: 0)
            content()
        }
        .frame(height: 30)
    }

    private func sourceRow(_ role: Role, _ slot: Slot?) -> some View {
        HStack(spacing: 10) {
            Group {
                if let slot {
                    Image(nsImage: NSImage(cgImage: slot.image,
                                           size: NSSize(width: slot.image.width, height: slot.image.height)))
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle().fill(.white.opacity(0.10))
                }
            }
            .frame(width: 46, height: 29)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(role.rawValue)
                    .font(.system(size: 11.5, weight: .medium))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if slot?.isDerived == true {
                        Image(systemName: "wand.and.stars").font(.system(size: 9))
                    }
                    Text(slot.map { $0.isDerived ? "generated · \($0.pixelDescription)" : $0.pixelDescription }
                         ?? "empty")
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .foregroundStyle(.white.opacity(0.5))
            }

            Spacer(minLength: 0)

            if slot != nil {
                Button { model.clear(role) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.55))
                .help("Remove")
            }
        }
        .padding(7)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(.white.opacity(0.13), lineWidth: 0.5)
        }
    }

    private var statusLine: some View {
        HStack(spacing: 7) {
            if model.isWorking {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: model.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(model.isError ? .orange : .green)
            }
            Text(model.status)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hairline: some View {
        Rectangle()
            .fill(.white.opacity(0.13))
            .frame(height: 0.5)
    }
}
