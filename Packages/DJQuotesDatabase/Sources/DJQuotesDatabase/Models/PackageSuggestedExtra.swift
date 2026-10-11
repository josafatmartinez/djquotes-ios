import Foundation
import GRDB

struct PackageSuggestedExtra: Codable {
    var packageId: String
    var catalogItemId: String
    var sortOrder: Int
}

extension PackageSuggestedExtra: FetchableRecord, PersistableRecord {
    static let databaseTableName = "package_suggested_extras"

    enum Columns: String, ColumnExpression {
        case packageId, catalogItemId, sortOrder
    }
}