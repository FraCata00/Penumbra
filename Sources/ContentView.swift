import SwiftUI

struct ContentView: View {
    @StateObject private var model = WallpaperModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: 0) {
                DropZone(role: .light, slot: model.light,
                         onPick: { model.load($0, into: .light) },
                         onClear: { model.clear(.light) })
                DropZone(role: .dark, slot: model.dark,
                         onPick: { model.load($0, into: .dark) },
                         onClear: { model.clear(.dark) })
            }
            .ignoresSafeArea()

            controls
                .padding(.bottom, 18)
                .padding(.horizontal, 18)
        }
        .frame(minWidth: 760, minHeight: 520)
    }

    private var controls: some View {
        GlassEffectContainer(spacing: 16) {
            VStack(spacing: 10) {
                if !model.status.isEmpty || model.isWorking {
                    statusPill
                }
                HStack(spacing: 14) {
                    labelled("Risoluzione") {
                        Picker("", selection: $model.resolution) {
                            ForEach(model.resolutionOptions) { Text($0.label).tag($0) }
                        }
                        .labelsHidden()
                        .frame(width: 190)
                    }

                    Divider().frame(height: 26)

                    labelled("Ritaglio") {
                        Picker("", selection: $model.fitMode) {
                            ForEach(FitMode.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                        .help(model.fitMode.help)
                    }

                    Divider().frame(height: 26)

                    labelled("Qualità") {
                        HStack(spacing: 8) {
                            Slider(value: $model.quality, in: 0.4...1.0).frame(width: 110)
                            Text(String(format: "%.2f", model.quality))
                                .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                        }
                    }

                    Divider().frame(height: 26)

                    Button("Salva .heic…") { model.save() }
                        .buttonStyle(.glass)
                        .disabled(!model.isReady || model.isWorking)

                    Button("Applica") { model.apply() }
                        .buttonStyle(.glassProminent)
                        .keyboardShortcut(.defaultAction)
                        .disabled(!model.isReady || model.isWorking)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 26))
            }
        }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            if model.isWorking {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: model.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(model.isError ? .orange : .green)
            }
            Text(model.status).lineLimit(2)
        }
        .font(.callout)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .glassEffect(.regular, in: .capsule)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.status)
    }

    private func labelled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
    }
}
