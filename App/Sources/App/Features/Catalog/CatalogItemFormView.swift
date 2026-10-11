import SwiftUI
import GRDB
import DJQuotesDatabase

struct CatalogItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    let vm: CatalogViewModel
    let existingItem: CatalogItem?
    let createdBy: String

    @State private var name: String
    @State private var type: CatalogItemType
    @State private var itemDescription: String
    @State private var salePrice: String
    @State private var internalCost: String

    init(vm: CatalogViewModel, existingItem: CatalogItem?, createdBy: String) {
        self.vm = vm
        self.existingItem = existingItem
        self.createdBy = createdBy
        _name = State(initialValue: existingItem?.name ?? "")
        _type = State(initialValue: existingItem?.type ?? .service)
        _itemDescription = State(initialValue: existingItem?.description ?? "")
        _salePrice = State(initialValue: existingItem?.salePrice ?? "")
        _internalCost = State(initialValue: existingItem?.internalCost ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "catalog.info")) {
                    TextField(String(localized: "catalog.name"), text: $name)
                    Picker(String(localized: "catalog.type"), selection: $type) {
                        ForEach(CatalogItemType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    TextField(String(localized: "catalog.description"), text: $itemDescription, axis: .vertical)
                }
                Section(String(localized: "catalog.pricing")) {
                    TextField(String(localized: "catalog.salePrice"), text: $salePrice).keyboardType(.decimalPad)
                    TextField(String(localized: "catalog.internalCost"), text: $internalCost).keyboardType(.decimalPad)
                }
                Section {
                    Button(existingItem == nil
                        ? String(localized: "catalog.create")
                        : String(localized: "common.save")
                    ) { Task { await submit() } }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || salePrice.isEmpty)
                }
            }
            .navigationTitle(existingItem == nil
                ? String(localized: "catalog.newItem")
                : String(localized: "catalog.editItem"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func submit() async {
        let price = salePrice.isEmpty ? "0.00" : salePrice
        let cost = internalCost.isEmpty ? nil : internalCost
        if let item = existingItem {
            guard await vm.update(item, name: name, type: type, description: itemDescription.nilIfEmpty, salePrice: price, internalCost: cost) else { return }
        } else {
            guard await vm.create(name: name, type: type, description: itemDescription.nilIfEmpty, salePrice: price, internalCost: cost, createdBy: createdBy) else { return }
        }
        dismiss()
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}