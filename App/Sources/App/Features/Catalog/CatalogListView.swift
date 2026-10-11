import SwiftUI
import GRDB
import DJQuotesDatabase
import DJQuotesDatabase

struct CatalogListView: View {
    @Environment(AuthManager.self) private var auth
    @State private var vm = CatalogViewModel()
    @State private var showForm = false
    @State private var editingItem: CatalogItem?
    @State private var showArchived = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                } else {
                    List {
                        ForEach(vm.filteredItems) { item in
                            Button { editingItem = item } label: {
                                CatalogRowView(item: item)
                            }
                            .swipeActions(edge: .trailing) {
                                if item.archived {
                                    Button(String(localized: "catalog.restore")) { Task { await vm.unarchive(item) } }.tint(.green)
                                } else {
                                    Button(String(localized: "catalog.archive")) { Task { await vm.archive(item) } }.tint(.orange)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $vm.searchText, prompt: String(localized: "common.search"))
            .navigationTitle("tab.catalog")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { editingItem = nil; showForm = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(String(localized: "catalog.allTypes")) { vm.selectedType = nil }
                        ForEach(CatalogItemType.allCases, id: \.self) { type in
                            Button(type.displayName) { vm.selectedType = type }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }
            }
            .sheet(isPresented: $showForm) {
                CatalogItemFormView(vm: vm, existingItem: nil, createdBy: auth.currentProfile?.id ?? "")
            }
            .sheet(item: $editingItem) { item in
                CatalogItemFormView(vm: vm, existingItem: item, createdBy: auth.currentProfile?.id ?? "")
            }
        }
        .task { await vm.load() }
    }
}

struct CatalogRowView: View {
    let item: CatalogItem
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.headline)
                Text(item.type.displayName).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.salePrice.formattedAsMoney()).font(.subheadline).fontWeight(.medium)
                if item.archived {
                    Text("Archived").font(.caption2).foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

extension CatalogItemType: CaseIterable {
    public static var allCases: [CatalogItemType] = [.service, .equipment, .accessory, .extra, .consumable]
    var displayName: String {
        switch self {
        case .service: String(localized: "catalog.type.service")
        case .equipment: String(localized: "catalog.type.equipment")
        case .accessory: String(localized: "catalog.type.accessory")
        case .extra: String(localized: "catalog.type.extra")
        case .consumable: String(localized: "catalog.type.consumable")
        }
    }
}

extension String {
    func formattedAsMoney() -> String {
        guard let decimal = Decimal(string: self) else { return "$0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: decimal as NSDecimalNumber) ?? "$0.00"
    }
}