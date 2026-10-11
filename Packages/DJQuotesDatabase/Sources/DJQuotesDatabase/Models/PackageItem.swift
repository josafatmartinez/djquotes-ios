import Foundation
import GRDB

struct PackageItem: Codable {
    var id: String
    var packageId: String
    var catalogItemId: String
    var quantity: String
    var unitPriceOverride: String?
    var isOptional: Bool
    var sortOrder: Int
}

extension PackageItem: FetchableRecord, PersistableRecord {
    static let databaseTableName = "package_items"

    enum Columns: String, ColumnExpression {
        case id, packageId, catalogItemId, quantity, unitPriceOverride, isOptional, sortOrder
    }
}