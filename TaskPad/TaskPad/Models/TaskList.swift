import Foundation
import SwiftData

@Model
final class TaskList {
    var name: String
    var symbolName: String
    var colorName: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.list)
    var tasks: [TaskItem] = []

    init(name: String, symbolName: String = "list.bullet", colorName: String = "blue") {
        self.name = name
        self.symbolName = symbolName
        self.colorName = colorName
        self.createdAt = .now
    }
}
