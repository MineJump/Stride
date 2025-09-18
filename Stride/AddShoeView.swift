import SwiftUI

struct AddShoeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vm: ShoesViewModel

    // If set, we're editing this shoe; otherwise adding
    let editing: Shoe?

    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var model: String = ""
    @State private var priceText: String = ""
    @State private var startDate: Date = Date()
    @FocusState private var priceFocused: Bool

    init(editing: Shoe? = nil) {
        self.editing = editing
    }

    // Parse user input to Double; accept comma or dot as decimal separator
    var price: Double? {
        let raw = priceText
            .replacingOccurrences(of: "€", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard raw.isEmpty == false else { return nil }
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "de_DE")
        nf.numberStyle = .decimal
        if let n = nf.number(from: raw) {
            return n.doubleValue
        }
        return Double(raw.replacingOccurrences(of: ",", with: "."))
    }

    var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Shoe") {
                    LabeledContent("Name") {
                        TextField("Name", text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Brand") {
                        TextField("Brand", text: $brand)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Model") {
                        TextField("Model", text: $model)
                            .multilineTextAlignment(.trailing)
                    }
                    // Single currency-like text field with € trailing
                    LabeledContent("Price") {
                        HStack(spacing: 6) {
                            TextField("0,00", text: $priceText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($priceFocused)
                                .onSubmit(formatPriceIfPossible)
                                .onChange(of: priceFocused) { wasFocused, isFocused in
                                    if wasFocused && !isFocused {
                                        formatPriceIfPossible()
                                    }
                                }
                            Text("€")
                                .foregroundStyle(.secondary)
                        }
                    }
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                }
            }
            .navigationTitle(isEditing ? "Edit Shoe" : "Add Shoe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTapped() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let shoe = editing {
                    name = shoe.name
                    brand = shoe.brand
                    model = shoe.model
                    if let p = shoe.price {
                        priceText = formatEUR(p, includeSymbol: false) // symbol shown as trailing label
                    } else {
                        priceText = ""
                    }
                    startDate = shoe.startDate
                }
            }
        }
    }

    private func saveTapped() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanModel = model.trimmingCharacters(in: .whitespacesAndNewlines)

        if var shoe = editing {
            shoe.name = cleanName
            shoe.brand = cleanBrand
            shoe.model = cleanModel
            shoe.price = price
            shoe.startDate = startDate
            vm.updateShoe(shoe)
        } else {
            vm.addShoe(
                name: cleanName,
                brand: cleanBrand,
                model: cleanModel,
                price: price,
                startDate: startDate
            )
        }
        Task { await vm.reloadAll() }
        dismiss()
    }

    private func formatPriceIfPossible() {
        guard let p = price else { return }
        priceText = formatEUR(p, includeSymbol: false)
    }

    private func formatEUR(_ value: Double, includeSymbol: Bool) -> String {
        let fmt = NumberFormatter()
        fmt.locale = Locale(identifier: "de_DE")
        fmt.numberStyle = .currency
        fmt.currencyCode = "EUR"
        fmt.minimumFractionDigits = 2
        fmt.maximumFractionDigits = 2
        let full = fmt.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        if includeSymbol { return full }
        // Strip leading currency symbol and spaces for the text field content
        return full.replacingOccurrences(of: "€", with: "").trimmingCharacters(in: .whitespaces)
    }
}
