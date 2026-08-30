import SwiftUI
import SwiftData

struct ListEditSheet: View {
    let list: TaskList?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var symbolName: String
    @State private var colorName: String

    init(list: TaskList?) {
        self.list = list
        _name = State(initialValue: list?.name ?? "")
        _symbolName = State(initialValue: list?.symbolName ?? ListSymbol.choices[0])
        _colorName = State(initialValue: list?.colorName ?? ListColor.blue.rawValue)
    }

    private let columns = Array(repeating: GridItem(.flexible()), count: 5)

    var body: some View {
        NavigationStack {
            Form {
                Section("Nome") {
                    TextField("Nome lista", text: $name)
                }

                Section("Colore") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(ListColor.allCases, id: \.rawValue) { option in
                            Circle()
                                .fill(option.color)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if option.rawValue == colorName {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { colorName = option.rawValue }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Icona") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(ListSymbol.choices, id: \.self) { symbol in
                            Image(systemName: symbol)
                                .font(.title3)
                                .frame(width: 32, height: 32)
                                .foregroundStyle(symbol == symbolName ? .white : .primary)
                                .background {
                                    Circle()
                                        .fill(symbol == symbolName ? (ListColor(rawValue: colorName) ?? .blue).color : Color.clear)
                                }
                                .onTapGesture { symbolName = symbol }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(list == nil ? "Nuova lista" : "Rinomina lista")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let list {
            list.name = trimmed
            list.symbolName = symbolName
            list.colorName = colorName
        } else {
            let newList = TaskList(name: trimmed, symbolName: symbolName, colorName: colorName)
            modelContext.insert(newList)
        }
        dismiss()
    }
}
