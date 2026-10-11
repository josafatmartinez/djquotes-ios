import Foundation
import GRDB

public struct CatalogItem: Codable, Identifiable {
    public var id: String
    public var name: String
    public var description: String?
    public var type: CatalogItemType
    public var salePrice: String
    public var internalCost: String?
    public var archived: Bool
    public var createdBy: String
    public var createdAt: Date
    public init(id: String, name: String, description: String?, type: CatalogItemType, salePrice: String, internalCost: String?, archived: Bool, createdBy: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.salePrice = salePrice
        self.internalCost = internalCost
        self.archived = archived
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
}

extension CatalogItem: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "catalog_items"

    public enum Columns: String, ColumnExpression {
        case id, name, description, type, salePrice, internalCost, archived, createdBy, createdAt
    }
}