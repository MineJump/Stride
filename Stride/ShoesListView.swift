import SwiftUI

struct ShoesListView: View {
    @EnvironmentObject var store: ShoeStore
    @EnvironmentObject var vm: ShoesViewModel
    @EnvironmentObject var activity: ActivityManager

    @State private var showingAdd = false
    @State private var showingProfile = false

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
                                Task { await vm.reloadAll(isInitial: false) }
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
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add Shoe")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingProfile = true } label: { Image(systemName: "person.crop.circle") }
                        .accessibilityLabel("Profile")
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
            .sheet(isPresented: $showingProfile) {
                NavigationStack {
                    ProfileFormView()
                        .navigationTitle("Profile")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    showingProfile = false
                                } label: {
                                    Image(systemName: "checkmark").foregroundStyle(.white)
                                }
                                
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                .accessibilityLabel("Done")
                            }
                        }
                }
                .presentationDetents([.medium, .large])
            }
            .refreshable {
                await vm.reloadAll(isInitial: false)
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil), actions: {
                Button("OK") { vm.errorMessage = nil }
            }, message: {
                Text(vm.errorMessage ?? "")
            })
        }
    }

    func authorizeTapped() async {
        await vm.requestHealthAccess()
    }

    func delete(at offsets: IndexSet) {
        vm.deleteShoes(at: offsets)
        Task { await vm.reloadAll(isInitial: false) }
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
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
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
