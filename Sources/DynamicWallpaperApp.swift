import SwiftUI

@main
struct DynamicWallpaperApp: App {
    var body: some Scene {
        Window("Dynamic Wallpaper", id: "main") {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}
