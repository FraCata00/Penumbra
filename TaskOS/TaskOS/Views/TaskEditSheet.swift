import SwiftUI
import SwiftData

struct TaskEditSheet: View {
    let task: TaskItem?
    let lists: [TaskList]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var notes: String
    @State private var priority: Priority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var selectedList: TaskList?

    init(task: TaskItem?, lists: [TaskList], defaultList: TaskList?) {
        self.task = task
        self.lists = lists
        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.notes ?? "")
        _priority = State(initialValue: task?.priority ?? .medium)
        _hasDueDate = State(initialValue: task?.dueDate != nil)
        _dueDate = State(initialValue: task?.dueDate ?? .now)
        _selectedList = State(initialValue: task?.list ?? defaultList)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Attività") {
                    TextField("Titolo", text: $title)
                    TextField("Note", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Lista") {
                    Picker("Lista", selection: $selectedList) {
                        ForEach(lists) { list in
                            Label(list.name, systemImage: list.symbolName)
                                .tag(Optional(list))
                        }
                    }
                }

                Section("Scadenza") {
                    Toggle("Imposta scadenza", isOn: $hasDueDate.animation())
                    if hasDueDate {
                        DatePicker("Data", selection: $dueDate)
                            .datePickerStyle(.graphical)
                    }
                }

                Section("Priorità") {
                    Picker("Priorità", selection: $priority) {
                        ForEach(Priority.allCases) { level in
                            Label(level.label, systemImage: level.symbolName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(task == nil ? "Nuova attività" : "Modifica attività")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || selectedList == nil)
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        let resolvedDueDate = hasDueDate ? dueDate : nil

        if let task {
            task.title = trimmed
            task.notes = notes
            task.priority = priority
            task.dueDate = resolvedDueDate
            task.list = selectedList
        } else {
            let newTask = TaskItem(
                title: trimmed,
                notes: notes,
                dueDate: resolvedDueDate,
                priority: priority,
                list: selectedList
            )
            modelContext.insert(newTask)
        }
        dismiss()
    }
}
