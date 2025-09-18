import Foundation

@MainActor
final class ShoesViewModel: ObservableObject {
    @Published var isAuthorized = false
    @Published var loading = false
    @Published var errorMessage: String?
    @Published var stats: [UUID: ShoeStats] = [:]

    let store: ShoeStore
    let hk: HealthKitManager
    let activity: ActivityManager

    struct ShoeStats: Equatable { var steps: Int; var km: Double }

    init(store: ShoeStore, hk: HealthKitManager, activity: ActivityManager) {
        self.store = store
        self.hk = hk
        self.activity = activity
    }

    func requestHealthAccess() async {
        do {
            try await hk.requestAuthorization()
            isAuthorized = true
            await reloadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reloadAll(isInitial: Bool = false) async {
        loading = true
        defer { loading = false }

        stats.removeAll()
        let now = Date()

        for shoe in store.shoes {
            let periods = activity.activePeriods(for: shoe.id)
            var totalSteps = 0
            var totalKm = 0.0

            if periods.isEmpty {
                do {
                    totalSteps = try await hk.steps(from: shoe.startDate, to: now)
                    totalKm = try await hk.distanceKilometers(from: shoe.startDate, to: now)
                } catch {
                    let msg = (error as NSError).localizedDescription.lowercased()
                    if msg.contains("no data") || msg.contains("no dato") {
                        // zero fallback
                    } else {
                        errorMessage = "Failed for \(shoe.name): \(error.localizedDescription)"
                    }
                }
            } else {
                for p in periods {
                    let end = p.endDate ?? now
                    guard end > p.startDate else { continue }
                    do {
                        totalSteps += try await hk.steps(from: p.startDate, to: end)
                        totalKm += try await hk.distanceKilometers(from: p.startDate, to: end)
                    } catch {
                        let msg = (error as NSError).localizedDescription.lowercased()
                        if msg.contains("no data") || msg.contains("no dato") {
                            // ignore this period
                        } else {
                            errorMessage = "Failed for \(shoe.name): \(error.localizedDescription)"
                        }
                    }
                }
            }

            stats[shoe.id] = ShoeStats(steps: totalSteps, km: totalKm)
        }
    }

    func addShoe(name: String, brand: String, model: String, price: Double?, startDate: Date) {
        store.addShoe(name: name, brand: brand, model: model, price: price, startDate: startDate)
    }

    func updateShoe(_ shoe: Shoe) {
        store.update(shoe)
    }

    func deleteShoes(at offsets: IndexSet) {
        let idsToDelete = offsets.compactMap { store.shoes[$0].id }
        store.delete(at: offsets)

        if let currentId = activity.currentActiveShoeId, idsToDelete.contains(currentId) {
            activity.closeCurrentPeriod()
        }
    }

    func activate(shoeId: UUID) {
        activity.activate(shoeId: shoeId)
    }
}
