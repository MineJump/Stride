import Foundation

struct ActivePeriod: Identifiable, Codable, Equatable {
    let id: UUID
    let shoeId: UUID
    let startDate: Date
    var endDate: Date?

    init(id: UUID = UUID(), shoeId: UUID, startDate: Date = Date(), endDate: Date? = nil) {
        self.id = id
        self.shoeId = shoeId
        self.startDate = startDate
        self.endDate = endDate
    }
}

@MainActor
final class ActivityManager: ObservableObject {
    @Published private(set) var periods: [ActivePeriod] = []

    private let storageKey = "active_periods"

    init() { load() }

    var currentActiveShoeId: UUID? {
        periods.first(where: { $0.endDate == nil })?.shoeId
    }

    func activate(shoeId: UUID, at date: Date = Date()) {
        if let idx = periods.firstIndex(where: { $0.endDate == nil }) {
            periods[idx].endDate = date
        }
        periods.insert(ActivePeriod(shoeId: shoeId, startDate: date), at: 0)
        save()
    }

    func activePeriods(for shoeId: UUID) -> [ActivePeriod] {
        periods.filter { $0.shoeId == shoeId }
    }

    func closeCurrentPeriod(endDate: Date = Date()) {
        if let idx = periods.firstIndex(where: { $0.endDate == nil }) {
            periods[idx].endDate = endDate
            save()
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([ActivePeriod].self, from: data) {
            periods = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(periods) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
