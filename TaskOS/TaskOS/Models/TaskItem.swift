import Foundation
import SwiftData

enum Priority: Int, CaseIterable, Identifiable, Comparable {
    case low = 0
    case medium = 1
    case high = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .low: return "Bassa"
        case .medium: return "Media"
        case .high: return "Alta"
        }
    }

    var symbolName: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "equal.circle"
        case .high: return "arrow.up.circle"
        }
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

@Model
final class TaskItem {
    var title: String
    var notes: String
    var isCompleted: Bool
    var dueDate: Date?
    var priorityRawValue: Int
    var createdAt: Date
    var list: TaskList?

    var priority: Priority {
        get { Priority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }

    init(
        title: String,
        notes: String = "",
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        priority: Priority = .medium,
        list: TaskList? = nil
    ) {
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priorityRawValue = priority.rawValue
        self.createdAt = .now
        self.list = list
    }
}
