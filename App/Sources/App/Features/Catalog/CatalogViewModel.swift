import Foundation
import DJQuotesDatabase
import GRDB

@MainActor
@Observable
final class CatalogViewModel {
    var items: [CatalogItem] = []
    var searchText = ""
    var selectedType: CatalogItemType?
    var isLoading = false
    var error: String?

    var filteredItems: [CatalogItem] {
        var result = items
        if let type = selectedType {
            result = result.filter { $0.type == type }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    func load() async {
        isLoading = true
        do {
            items = try await DatabaseManager.shared.read { db in
                try CatalogItem.order(CatalogItem.Columns.name.asc).fetchAll(db)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func create(name: String, type: CatalogItemType, description: String?, salePrice: String, internalCost: String?, createdBy: String) async -> Bool {
        let item = CatalogItem(
            id: UUID().uuidString,
            name: name,
            description: description,
            type: type,
            salePrice: salePrice,
            internalCost: internalCost,
            archived: false,
            createdBy: createdBy,
            createdAt: Date()
        )
        do {
            try await DatabaseManager.shared.write { db in try item.insert(db) }
            await load()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func update(_ item: CatalogItem, name: String, type: CatalogItemType, description: String?, salePrice: String, internalCost: String?) async -> Bool {
        var updated = item
        updated.name = name
        updated.type = type
        updated.description = description
        updated.salePrice = salePrice
        updated.internalCost = internalCost
        do {
            try await DatabaseManager.shared.write { db in try updated.update(db) }
            await load()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func archive(_ item: CatalogItem) async {
        do {
            try await DatabaseManager.shared.write { db in
                var archived = item
                archived.archived = true
                try archived.update(db)
            }
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func unarchive(_ item: CatalogItem) async {
        do {
            try await DatabaseManager.shared.write { db in
                var restored = item
                restored.archived = false
                try restored.update(db)
            }
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}