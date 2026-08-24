import AppKit
import SwiftUI

/// Shown when a newer release exists. Downloading opens the disk image in the
/// browser; installing stays a conscious drag into Applications.
struct UpdateSheet: View {
    let release: GitHubRelease
    let currentVersion: String
    let onSkip: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 13) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Penumbra \(release.version) is available")
                        .font(.system(size: 15, weight: .semibold))
                    Text("You have \(currentVersion)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            if let notes, !notes.isEmpty {
                ScrollView {
                    Text(notes)
                        .font(.system(size: 12))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 170)
                .padding(10)
                .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            HStack {
                Button("Skip this version", action: onSkip)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Later", action: onDismiss)
                Button("Download") {
                    NSWorkspace.shared.open(release.diskImage ?? release.htmlURL)
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .controlSize(.large)
        }
        .padding(20)
        .frame(width: 440)
    }

    private var notes: String? {
        release.body?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
