import SwiftUI

@main
struct PenumbraApp: App {
    @StateObject private var updates = UpdateChecker()
    @State private var showingSplash = true

    var body: some Scene {
        Window("Penumbra", id: "main") {
            ZStack {
                ContentView()

                if showingSplash {
                    SplashView(updates: updates) {
                        withAnimation(.easeInOut(duration: 0.45)) { showingSplash = false }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            // The splash presents its own update offer, so the sheet is only for
            // checks the user asked for from the menu.
            .sheet(item: sheetRelease) { release in
                UpdateSheet(
                    release: release,
                    currentVersion: updates.currentVersion,
                    onSkip: { updates.skip(release) },
                    onDismiss: { updates.pending = nil }
                )
            }
            .alert("You're up to date", isPresented: $updates.isUpToDate) {
                Button("OK") {}
            } message: {
                Text("Penumbra \(updates.currentVersion) is the latest version.")
            }
            .alert("Could not check for updates", isPresented: hasFailure) {
                Button("OK") {}
            } message: {
                Text(updates.failure ?? "")
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    Task { await updates.check(userInitiated: true) }
                }
                .disabled(updates.isChecking)
            }
        }
    }

    private var sheetRelease: Binding<GitHubRelease?> {
        Binding(get: { showingSplash ? nil : updates.pending },
                set: { updates.pending = $0 })
    }

    private var hasFailure: Binding<Bool> {
        Binding(get: { updates.failure != nil },
                set: { if !$0 { updates.failure = nil } })
    }
}
