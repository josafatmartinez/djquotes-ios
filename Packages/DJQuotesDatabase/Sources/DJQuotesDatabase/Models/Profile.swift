import Foundation
import GRDB

struct Profile: Codable {
    var id: String
    var name: String
    var role: ProfileRole
    var pinHash: String
    var isActive: Bool
    var createdAt: Date
}

extension Profile: FetchableRecord, PersistableRecord {
    static let databaseTableName = "profiles"

    enum Columns: String, ColumnExpression {
        case id, name, role, pinHash, isActive, createdAt
    }
}