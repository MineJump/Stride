import SwiftUI

struct ShoesListView: View {
    @EnvironmentObject var store: ShoeStore
    @EnvironmentObject var vm: ShoesViewModel
    @EnvironmentObject var activity: ActivityManager

    @State private var showingAdd = false
    @State private var showingProfile = false

    // EDIT: hold the shoe being edited and sheet flag
    @State private var editingShoe: Shoe? = nil
    @State private var showingEdit = false

    // Track which rows are expanded
    @State private var expanded: Set<UUID> = []

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
                            ShoeRow(
                                shoe: shoe,
                                steps: steps,
                                km: km,
                                isExpanded: expanded.contains(shoe.id),
                                toggleExpanded: {
                                    if expanded.contains(shoe.id) {
                                        expanded.remove(shoe.id)
                                    } else {
                                        expanded.insert(shoe.id)
                                    }
                                },
                                onActivate: {
                                    vm.activate(shoeId: shoe.id)
                                    Task { await vm.reloadAll(isInitial: false) }
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    if let index = store.shoes.firstIndex(of: shoe) {
                                        delete(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    editingShoe = shoe
                                    showingEdit = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.orange)
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
            .sheet(isPresented: $showingEdit, onDismiss: { editingShoe = nil }) {
                if let shoe = editingShoe {
                    AddShoeView(editing: shoe)
                        .presentationDetents([.medium])
                }
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
    let isExpanded: Bool
    var toggleExpanded: () -> Void
    var onActivate: (() -> Void)?

    @EnvironmentObject var activity: ActivityManager

    var isActive: Bool {
        activity.currentActiveShoeId == shoe.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: name, steps, km, always-visible Activate button, expand chevron
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Button(action: toggleExpanded) {
                        HStack(spacing: 6) {
                            Text(shoe.name)
                                .font(.headline)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundStyle(.secondary)
                                .imageScale(.small)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        Label("\(steps)", systemImage: "figure.walk")
                            .labelStyle(.titleAndIcon)
                        Text("·")
                            .foregroundStyle(.secondary)
                        Label("\(Int(km.rounded())) km", systemImage: "base.unit")
                            .labelStyle(.titleAndIcon)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button(isActive ? "Active" : "Activate") {
                    onActivate?()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                .buttonStyle(.borderedProminent)
                .tint(isActive ? .green : .blue)
                .disabled(isActive)
            }

            // Expanded details
            if isExpanded {
                Group {
                    LabeledContent("Brand") {
                        Text(shoe.brand.isEmpty ? "—" : shoe.brand).foregroundStyle(.secondary)
                    }
                    LabeledContent("Model") {
                        Text(shoe.model.isEmpty ? "—" : shoe.model).foregroundStyle(.secondary)
                    }
                    LabeledContent("Price") {
                        if let price = shoe.price {
                            Text(price, format: .currency(code: "EUR"))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("—").foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent("Start date") {
                        Text(shoe.startDate, style: .date).foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(shoe.name), \(steps) steps, \(Int(km.rounded())) kilometers, \(isActive ? "active" : "inactive")")
    }
}
