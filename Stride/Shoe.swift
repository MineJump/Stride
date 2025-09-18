import Foundation

struct Shoe: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var brand: String
    var model: String
    var price: Double?
    var startDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        brand: String = "",
        model: String = "",
        price: Double? = nil,
        startDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.model = model
        self.price = price
        self.startDate = startDate
    }

    // Backward-compatible decoding (for old saved data without new fields)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.brand = try container.decodeIfPresent(String.self, forKey: .brand) ?? ""
        self.model = try container.decodeIfPresent(String.self, forKey: .model) ?? ""
        self.price = try container.decodeIfPresent(Double.self, forKey: .price)
        self.startDate = try container.decodeIfPresent(Date.self, forKey: .startDate) ?? Date()
    }
}

final class ShoeStore: ObservableObject {
    @Published var shoes: [Shoe] = []

    private let storageKey = "shoes"

    init() { load() }

    func addShoe(
        name: String,
        brand: String,
        model: String,
        price: Double?,
        startDate: Date
    ) {
        shoes.append(Shoe(name: name, brand: brand, model: model, price: price, startDate: startDate))
        save()
    }

    func delete(at offsets: IndexSet) {
        shoes.remove(atOffsets: offsets)
        save()
    }

    func update(_ shoe: Shoe) {
        if let idx = shoes.firstIndex(where: { $0.id == shoe.id }) {
            shoes[idx] = shoe
            save()
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([Shoe].self, from: data) {
            shoes = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(shoes) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        // Debug: print("Saved shoes:", shoes.map(\.name))
    }
}
