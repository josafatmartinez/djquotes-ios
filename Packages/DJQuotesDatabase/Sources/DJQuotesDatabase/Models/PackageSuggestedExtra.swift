import Foundation
import GRDB

public struct PackageSuggestedExtra: Codable, Identifiable {
    public var packageId: String
    public var catalogItemId: String
    public var sortOrder: Int

    public var id: String { "\(packageId)-\(catalogItemId)" }
    public init(packageId: String, catalogItemId: String, sortOrder: Int) {
        self.packageId = packageId
        self.catalogItemId = catalogItemId
        self.sortOrder = sortOrder
    }
}

extension PackageSuggestedExtra: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "package_suggested_extras"

    public enum Columns: String, ColumnExpression {
        case packageId, catalogItemId, sortOrder
    }
}