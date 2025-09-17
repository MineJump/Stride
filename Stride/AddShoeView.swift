import SwiftUI

struct AddShoeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vm: ShoesViewModel

    @State private var name: String = ""
    @State private var startDate: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Shoe") {
                    TextField("Name (e.g., Nike Pegasus)", text: $name)
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Shoe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        vm.addShoe(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            startDate: startDate
                        )
                        Task { await vm.reloadAll() }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
