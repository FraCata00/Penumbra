import SwiftUI
import SwiftData

struct SidebarView: View {
    let lists: [TaskList]
    @Binding var selection: SidebarItem?

    @Environment(\.modelContext) private var modelContext
    @State private var isAddingList = false
    @State private var listToRename: TaskList?

    var body: some View {
        List(selection: $selection) {
            Section("Panoramica") {
                sidebarRow(.all)
                sidebarRow(.today)
                sidebarRow(.completed)
            }

            Section("Liste") {
                ForEach(lists) { list in
                    sidebarRow(.list(list))
                        .contextMenu {
                            Button("Rinomina") { listToRename = list }
                            Button("Elimina", role: .destructive) { delete(list) }
                        }
                }
                .onDelete(perform: deleteLists)
            }
        }
        .navigationTitle("TaskPad")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingList = true
                } label: {
                    Label("Nuova lista", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingList) {
            ListEditSheet(list: nil)
        }
        .sheet(item: $listToRename) { list in
            ListEditSheet(list: list)
        }
    }

    private func sidebarRow(_ item: SidebarItem) -> some View {
        Label(item.title, systemImage: item.symbolName)
            .tag(item)
    }

    private func deleteLists(at offsets: IndexSet) {
        for index in offsets {
            delete(lists[index])
        }
    }

    private func delete(_ list: TaskList) {
        if case .list(let selected) = selection, selected.persistentModelID == list.persistentModelID {
            selection = .all
        }
        modelContext.delete(list)
    }
}
