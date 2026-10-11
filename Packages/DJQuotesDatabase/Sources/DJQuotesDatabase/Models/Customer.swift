import Foundation
import GRDB

public struct Customer: Codable, Identifiable {
    public var id: String
    public var name: String
    public var phone: String
    public var email: String?
    public var createdBy: String
    public var createdAt: Date
    public init(id: String, name: String, phone: String, email: String?, createdBy: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.phone = phone
        self.email = email
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
}

extension Customer: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "customers"

    public enum Columns: String, ColumnExpression {
        case id, name, phone, email, createdBy, createdAt
    }
}