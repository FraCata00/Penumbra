import Foundation

enum SidebarItem: Hashable {
    case all
    case today
    case completed
    case list(TaskList)

    var title: String {
        switch self {
        case .all: return "Tutte"
        case .today: return "Oggi"
        case .completed: return "Completate"
        case .list(let list): return list.name
        }
    }

    var symbolName: String {
        switch self {
        case .all: return "tray.full"
        case .today: return "calendar"
        case .completed: return "checkmark.circle"
        case .list(let list): return list.symbolName
        }
    }
}
