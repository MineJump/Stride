import Foundation

@MainActor
final class ShoesViewModel: ObservableObject {
    @Published var isAuthorized = false
    @Published var loading = false
    @Published var initialLoading = true
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

    // New signature with triggerInitialLoading
    func requestHealthAccess(triggerInitialLoading: Bool) async {
        do {
            try await hk.requestAuthorization()
            isAuthorized = true
            // Only enable the big initial overlay when explicitly requested (app-start path)
            await reloadAll(isInitial: triggerInitialLoading)
        } catch {
            errorMessage = error.localizedDescription
            // If we were in an initial flow, ensure we dismiss the overlay on failure
            if triggerInitialLoading {
                initialLoading = false
            }
        }
    }

    func reloadAll(isInitial: Bool = false) async {
        if isInitial { initialLoading = true }
        loading = true
        defer {
            loading = false
            if isInitial { initialLoading = false }
        }

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

    func addShoe(name: String, startDate: Date) {
        store.addShoe(name: name, startDate: startDate)
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
