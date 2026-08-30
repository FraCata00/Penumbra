import SwiftUI

struct TaskRowView: View {
    @Bindable var task: TaskItem

    var body: some View {
        HStack(spacing: 12) {
            Button {
                task.isCompleted.toggle()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    if let due = task.dueDate {
                        Label(due.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    }
                    if let listName = task.list?.name {
                        Label(listName, systemImage: "folder")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: task.priority.symbolName)
                .foregroundStyle(priorityColor)
        }
        .padding(.vertical, 4)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low: return .secondary
        case .medium: return .orange
        case .high: return .red
        }
    }
}
