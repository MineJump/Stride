import SwiftUI

@main
struct StrideApp: App {
    @StateObject private var store: ShoeStore
    @StateObject private var vm: ShoesViewModel
    @StateObject private var activity: ActivityManager

    init() {
        let store = ShoeStore()
        let hk = HealthKitManager.shared
        let activity = ActivityManager()
        _store = StateObject(wrappedValue: store)
        _activity = StateObject(wrappedValue: activity)
        _vm = StateObject(wrappedValue: ShoesViewModel(store: store, hk: hk, activity: activity))
    }

    var body: some Scene {
        WindowGroup {
            ShoesListView()
                .environmentObject(store)
                .environmentObject(vm)
                .environmentObject(activity)
        }
    }
}
