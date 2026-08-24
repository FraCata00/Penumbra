import SwiftUI

@main
struct PenumbraApp: App {
    var body: some Scene {
        Window("Penumbra", id: "main") {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}
