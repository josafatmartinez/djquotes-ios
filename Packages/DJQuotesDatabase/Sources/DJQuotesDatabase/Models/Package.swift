import Foundation
import GRDB

struct Package: Codable {
    var id: String
    var name: String
    var description: String?
    var pricingMode: PackagePricingMode
    var commercialPrice: String?
    var manualPrice: String?
    var suggestedInstallerCount: Int
    var isActive: Bool
    var createdBy: String
    var createdAt: Date
}

extension Package: FetchableRecord, PersistableRecord {
    static let databaseTableName = "packages"

    enum Columns: String, ColumnExpression {
        case id, name, description, pricingMode, commercialPrice, manualPrice, suggestedInstallerCount, isActive, createdBy, createdAt
    }
}