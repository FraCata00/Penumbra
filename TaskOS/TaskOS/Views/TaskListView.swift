import SwiftUI
import SwiftData

struct TaskListView: View {
    let selection: SidebarItem

    @Query(sort: [
        SortDescriptor(\TaskItem.isCompleted),
        SortDescriptor(\TaskItem.dueDate, order: .forward),
        SortDescriptor(\TaskItem.createdAt, order: .reverse)
    ]) private var allTasks: [TaskItem]

    @Query private var lists: [TaskList]

    @Environment(\.modelContext) private var modelContext
    @State private var isAddingTask = false
    @State private var taskToEdit: TaskItem?

    private var tasks: [TaskItem] {
        switch selection {
        case .all:
            return allTasks
        case .today:
            return allTasks.filter { task in
                guard let due = task.dueDate else { return false }
                return Calendar.current.isDateInToday(due)
            }
        case .completed:
            return allTasks.filter(\.isCompleted)
        case .list(let list):
            return allTasks.filter { $0.list?.persistentModelID == list.persistentModelID }
        }
    }

    private var defaultList: TaskList? {
        if case .list(let list) = selection { return list }
        return lists.first
    }

    var body: some View {
        Group {
            if tasks.isEmpty {
                ContentUnavailableView(
                    "Nessuna attività",
                    systemImage: selection.symbolName,
                    description: Text(emptyMessage)
                )
            } else {
                List {
                    ForEach(tasks) { task in
                        TaskRowView(task: task)
                            .contentShape(Rectangle())
                            .onTapGesture { taskToEdit = task }
                    }
                    .onDelete(perform: deleteTasks)
                }
            }
        }
        .navigationTitle(selection.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingTask = true
                } label: {
                    Label("Nuova attività", systemImage: "plus")
                }
                .disabled(lists.isEmpty)
            }
        }
        .sheet(isPresented: $isAddingTask) {
            TaskEditSheet(task: nil, lists: lists, defaultList: defaultList)
        }
        .sheet(item: $taskToEdit) { task in
            TaskEditSheet(task: task, lists: lists, defaultList: task.list)
        }
    }

    private var emptyMessage: String {
        if lists.isEmpty {
            return "Crea prima una lista dalla barra laterale."
        }
        switch selection {
        case .all: return "Aggiungi la tua prima attività."
        case .today: return "Nessuna scadenza per oggi."
        case .completed: return "Non hai ancora completato nulla."
        case .list: return "Aggiungi un'attività a questa lista."
        }
    }

    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tasks[index])
        }
    }
}
