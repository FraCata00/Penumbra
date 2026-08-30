import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \TaskList.name) private var lists: [TaskList]
    @State private var selection: SidebarItem? = .all

    var body: some View {
        NavigationSplitView {
            SidebarView(lists: lists, selection: $selection)
        } detail: {
            TaskListView(selection: selection ?? .all)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TaskList.self, TaskItem.self], inMemory: true)
}
