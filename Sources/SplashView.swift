import AppKit
import SwiftUI

/// Brief launch screen. It doubles as the place where an available update shows
/// up: the check runs while the splash is on screen, so a new version is offered
/// before the app gets in the way, instead of interrupting later.
struct SplashView: View {
    @ObservedObject var updates: UpdateChecker
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.30, green: 0.56, blue: 0.76),
                         Color(red: 0.04, green: 0.05, blue: 0.11)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                Spacer()

                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 112, height: 112)
                    .shadow(color: .black.opacity(0.35), radius: 22, y: 10)
                    .scaleEffect(appeared ? 1 : 0.94)
                    .opacity(appeared ? 1 : 0)

                Text("Penumbra")
                    .font(.system(size: 31, weight: .semibold))
                    .padding(.top, 16)

                Text("the band between full light and full shadow")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.62))
                    .padding(.top, 5)

                Text("Version \(updates.currentVersion)")
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.42))
                    .padding(.top, 10)

                Spacer()

                status
                    .frame(height: 76)
                    .padding(.bottom, 26)
            }
            .foregroundStyle(.white)
            .opacity(appeared ? 1 : 0)
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { if updates.pending == nil { onDismiss() } }
        .task {
            withAnimation(.easeOut(duration: 0.45)) { appeared = true }
            Task { await updates.checkOnLaunch() }

            try? await Task.sleep(for: .milliseconds(1500))
            // Let a check that is still in flight finish, but never hang on it.
            var waited = 0
            while updates.isChecking && waited < 4000 {
                try? await Task.sleep(for: .milliseconds(100))
                waited += 100
            }
            if updates.pending == nil { onDismiss() }
        }
    }

    @ViewBuilder
    private var status: some View {
        if updates.isChecking {
            HStack(spacing: 9) {
                ProgressView().controlSize(.small).tint(.white)
                Text("Checking for updates…")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .transition(.opacity)
        } else if let release = updates.pending {
            VStack(spacing: 11) {
                Text("Penumbra \(release.version) is available")
                    .font(.system(size: 13, weight: .medium))

                HStack(spacing: 9) {
                    Button("Skip") {
                        updates.skip(release)
                        onDismiss()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.55))
                    .font(.system(size: 12))

                    Button("Later") {
                        updates.pending = nil
                        onDismiss()
                    }
                    .buttonStyle(.glass)

                    Button("Download") {
                        NSWorkspace.shared.open(release.diskImage ?? release.htmlURL)
                        updates.pending = nil
                        onDismiss()
                    }
                    .buttonStyle(.glassProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}
