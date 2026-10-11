import Foundation
import GRDB

public struct PackageItem: Codable, Identifiable {
    public var id: String
    public var packageId: String
    public var catalogItemId: String
    public var quantity: String
    public var unitPriceOverride: String?
    public var isOptional: Bool
    public var sortOrder: Int
    public init(id: String, packageId: String, catalogItemId: String, quantity: String, unitPriceOverride: String?, isOptional: Bool, sortOrder: Int) {
        self.id = id
        self.packageId = packageId
        self.catalogItemId = catalogItemId
        self.quantity = quantity
        self.unitPriceOverride = unitPriceOverride
        self.isOptional = isOptional
        self.sortOrder = sortOrder
    }
}

extension PackageItem: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "package_items"

    public enum Columns: String, ColumnExpression {
        case id, packageId, catalogItemId, quantity, unitPriceOverride, isOptional, sortOrder
    }
}