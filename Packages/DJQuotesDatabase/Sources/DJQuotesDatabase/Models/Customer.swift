import Foundation
import GRDB

struct Customer: Codable {
    var id: String
    var name: String
    var phone: String
    var email: String?
    var createdBy: String
    var createdAt: Date
}

extension Customer: FetchableRecord, PersistableRecord {
    static let databaseTableName = "customers"

    enum Columns: String, ColumnExpression {
        case id, name, phone, email, createdBy, createdAt
    }
}