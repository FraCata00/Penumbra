import SwiftUI
import SwiftData

@main
struct TaskPadApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [TaskList.self, TaskItem.self])
    }
}
