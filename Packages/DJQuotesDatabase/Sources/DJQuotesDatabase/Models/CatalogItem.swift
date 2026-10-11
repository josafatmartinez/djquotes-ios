import Foundation
import GRDB

struct CatalogItem: Codable {
    var id: String
    var name: String
    var description: String?
    var type: CatalogItemType
    var salePrice: String
    var internalCost: String?
    var archived: Bool
    var createdBy: String
    var createdAt: Date
}

extension CatalogItem: FetchableRecord, PersistableRecord {
    static let databaseTableName = "catalog_items"

    enum Columns: String, ColumnExpression {
        case id, name, description, type, salePrice, internalCost, archived, createdBy, createdAt
    }
}