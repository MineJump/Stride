import SwiftUI

struct ShoesListView: View {
    @EnvironmentObject var store: ShoeStore
    @EnvironmentObject var vm: ShoesViewModel
    @EnvironmentObject var activity: ActivityManager

    @State private var showingAdd = false
    @State private var showToast = false

    var body: some View {
        NavigationStack {
            Group {
                if store.shoes.isEmpty {
                    ContentUnavailableView {
                        Label("No shoes yet", systemImage: "shoe")
                    } description: {
                        Text("Add your first pair to track steps and km.")
                    }
                } else {
                    List {
                        ForEach(store.shoes) { shoe in
                            let steps = vm.stats[shoe.id]?.steps ?? 0
                            let km = vm.stats[shoe.id]?.km ?? 0.0
                            ShoeRow(shoe: shoe, steps: steps, km: km) {
                                vm.activate(shoeId: shoe.id)
                                Task { await vm.reloadAll() }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Stride")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            // Manually requesting Health access should NOT show the big initial loading overlay.
                            await vm.requestHealthAccess(triggerInitialLoading: false)
                        }
                    } label: {
                        Image(systemName: vm.isAuthorized ? "checkmark.shield" : "shield")
                    }
                    .help("Authorize Health access")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Shoe")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await vm.reloadAll() }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation { showToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation { showToast = false }
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh")
                }
            }
            .overlay(alignment: .top) {
                if vm.initialLoading {
                    LoadingView()
                }
            }
            .task {
                if vm.isAuthorized == false {
                    await authorizeTapped()
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddShoeView()
                    .presentationDetents([.medium])
            }
            .refreshable {
                await vm.reloadAll()
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil), actions: {
                Button("OK") { vm.errorMessage = nil }
            }, message: {
                Text(vm.errorMessage ?? "")
            })
        }
    }

    func authorizeTapped() async {
        // App-start auto path should still be allowed to show the initial overlay.
        await vm.requestHealthAccess(triggerInitialLoading: true)
    }

    func delete(at offsets: IndexSet) {
        vm.deleteShoes(at: offsets)
        Task { await vm.reloadAll() }
    }
}

struct ShoeRow: View {
    let shoe: Shoe
    let steps: Int
    let km: Double
    var onActivate: (() -> Void)?

    @EnvironmentObject var activity: ActivityManager

    var isActive: Bool {
        activity.currentActiveShoeId == shoe.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    if isActive {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.yellow)
                            .accessibilityHidden(true)
                    }
                    Text(shoe.name)
                        .font(.headline)
                }
                Spacer()
                Text("\(Int(km.rounded())) km")
                    .font(.subheadline)
            }
            HStack {
                Text("Steps: \(steps)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(isActive ? "Active" : "Activate") {
                    onActivate?()
                }
                .buttonStyle(.borderedProminent)
                .tint(isActive ? .green : .blue)
                .disabled(isActive)
            }
            .font(.caption)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(shoe.name), \(steps) steps, \(Int(km.rounded())) kilometers, \(isActive ? "active" : "inactive")")
    }
}
