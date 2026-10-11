import SwiftUI
import GRDB
import DJQuotesDatabase

struct PackageFormView: View {
    @Environment(\.dismiss) private var dismiss
    let vm: PackageViewModel
    let existingPackage: Package?
    let createdBy: String

    @State private var name: String
    @State private var pricingMode: PackagePricingMode
    @State private var packageDescription: String
    @State private var selectedItems: [FormItem]
    @State private var selectedExtras: Set<String>

    struct FormItem: Identifiable {
        let id: String
        let catalogItemId: String
        var quantity: String
        var unitPriceOverride: String
        var isOptional: Bool
    }

    init(vm: PackageViewModel, existingPackage: Package?, createdBy: String) {
        self.vm = vm
        self.existingPackage = existingPackage
        self.createdBy = createdBy
        _name = State(initialValue: existingPackage?.name ?? "")
        _pricingMode = State(initialValue: existingPackage?.pricingMode ?? .automatic)
        _packageDescription = State(initialValue: existingPackage?.description ?? "")
        _selectedExtras = State(initialValue: Set(existingPackage.map { _ in [] } ?? []))
        _selectedItems = State(initialValue: [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "packages.info")) {
                    TextField(String(localized: "packages.name"), text: $name)
                    Picker(String(localized: "packages.mode"), selection: $pricingMode) {
                        ForEach([PackagePricingMode.automatic, .commercial, .manual], id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    TextField(String(localized: "packages.description"), text: $packageDescription, axis: .vertical)
                }

                Section(String(localized: "packages.items")) {
                    ForEach($selectedItems) { $item in
                        HStack {
                            if let catItem = vm.catalogItems.first(where: { $0.id == item.catalogItemId }) {
                                VStack(alignment: .leading) {
                                    Text(catItem.name).font(.subheadline)
                                    Text("Qty: \(item.quantity)").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Toggle("Opt", isOn: $item.isOptional).labelsHidden()
                            }
                        }
                    }
                    .onDelete { selectedItems.remove(atOffsets: $0) }

                    Button(String(localized: "packages.addItem")) { addItem() }
                }

                Section(String(localized: "packages.suggestedExtras")) {
                    ForEach(vm.catalogItems) { catItem in
                        HStack {
                            Text(catItem.name).font(.subheadline)
                            Spacer()
                            if selectedExtras.contains(catItem.id) {
                                Image(systemName: "checkmark").foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedExtras.contains(catItem.id) { selectedExtras.remove(catItem.id) }
                            else { selectedExtras.insert(catItem.id) }
                        }
                    }
                }

                Section {
                    Button(existingPackage == nil
                        ? String(localized: "packages.create")
                        : String(localized: "common.save")
                    ) { Task { await submit() } }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle(existingPackage == nil
                ? String(localized: "packages.new")
                : String(localized: "packages.edit"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            let existingId = existingPackage?.id
            if let items = existingId.flatMap({ vm.packageItems[$0] }) {
                selectedItems = items.map {
                    FormItem(id: UUID().uuidString, catalogItemId: $0.catalogItemId, quantity: $0.quantity, unitPriceOverride: $0.unitPriceOverride ?? "", isOptional: $0.isOptional)
                }
            }
            if let extras = existingId.flatMap({ vm.packageExtras[$0] }) {
                selectedExtras = Set(extras.map(\.catalogItemId))
            }
        }
    }

    private func addItem() {
        selectedItems.append(FormItem(id: UUID().uuidString, catalogItemId: UUID().uuidString, quantity: "1", unitPriceOverride: "", isOptional: false))
    }

    private func submit() async {
        let items = selectedItems.map {
            (catalogItemId: $0.catalogItemId, quantity: $0.quantity, unitPriceOverride: $0.unitPriceOverride.nilIfEmpty, isOptional: $0.isOptional)
        }
        guard await vm.save(
            existingId: existingPackage?.id,
            name: name, pricingMode: pricingMode,
            description: packageDescription.nilIfEmpty,
            items: items,
            extraItemIds: Array(selectedExtras),
            createdBy: createdBy
        ) else { return }
        dismiss()
    }
}