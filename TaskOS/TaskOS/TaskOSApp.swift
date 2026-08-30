import SwiftUI
import SwiftData

@main
struct TaskOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [TaskList.self, TaskItem.self])
    }
}
