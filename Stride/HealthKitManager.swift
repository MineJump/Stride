import Foundation
import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var stepType: HKQuantityType { HKQuantityType.quantityType(forIdentifier: .stepCount)! }
    private var distanceType: HKQuantityType { HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)! }

    func requestAuthorization() async throws {
        guard isAvailable else {
            throw NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Health data not available"])
        }
        try await healthStore.requestAuthorization(toShare: [], read: [stepType, distanceType])
    }

    func steps(from start: Date, to end: Date) async throws -> Int {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let sum = try await sumQuantity(for: stepType, unit: .count(), predicate: predicate)
        return Int(sum)
    }

    func distanceKilometers(from start: Date, to end: Date) async throws -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let meters = try await sumQuantity(for: distanceType, unit: .meter(), predicate: predicate)
        return meters / 1000.0
    }

    private func sumQuantity(for type: HKQuantityType,
                             unit: HKUnit,
                             predicate: NSPredicate?) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, result, error in
                if let error = error {
                    let msg = (error as NSError).localizedDescription.lowercased()
                    if msg.contains("no data") || msg.contains("no dato") {
                        continuation.resume(returning: 0)
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            self.healthStore.execute(query)
        }
    }
}
