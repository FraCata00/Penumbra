import SwiftUI

@main
struct PenumbraApp: App {
    @StateObject private var updates = UpdateChecker()

    var body: some Scene {
        Window("Penumbra", id: "main") {
            ContentView()
                .task { await updates.checkOnLaunch() }
                .sheet(item: $updates.pending) { release in
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

    private var hasFailure: Binding<Bool> {
        Binding(get: { updates.failure != nil },
                set: { if !$0 { updates.failure = nil } })
    }
}
