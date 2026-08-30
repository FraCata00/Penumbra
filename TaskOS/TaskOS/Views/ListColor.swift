import SwiftUI

enum ListColor: String, CaseIterable {
    case red, orange, yellow, green, mint, teal, blue, indigo, purple, pink, gray

    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        case .gray: return .gray
        }
    }
}

extension TaskList {
    var displayColor: Color {
        (ListColor(rawValue: colorName) ?? .blue).color
    }
}

enum ListSymbol {
    static let choices = [
        "list.bullet", "briefcase", "cart", "house", "book",
        "heart", "airplane", "graduationcap", "dumbbell", "leaf",
        "gamecontroller", "gift", "star", "flag", "folder"
    ]
}
