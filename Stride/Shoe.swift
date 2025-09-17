import Foundation

struct Shoe: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var startDate: Date

    init(id: UUID = UUID(), name: String, startDate: Date = Date()) {
        self.id = id
        self.name = name
        self.startDate = startDate
    }
}

final class ShoeStore: ObservableObject {
    @Published var shoes: [Shoe] = []

    private let storageKey = "shoes"

    init() { load() }

    func addShoe(name: String, startDate: Date) {
        shoes.append(Shoe(name: name, startDate: startDate))
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
