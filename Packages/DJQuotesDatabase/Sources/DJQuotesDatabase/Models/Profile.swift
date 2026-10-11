import Foundation
import GRDB

public struct Profile: Codable, Hashable, Identifiable {
    public var id: String
    public var name: String
    public var role: ProfileRole
    public var pinHash: String
    public var isActive: Bool
    public var createdAt: Date
    public init(id: String, name: String, role: ProfileRole, pinHash: String, isActive: Bool, createdAt: Date) {
        self.id = id
        self.name = name
        self.role = role
        self.pinHash = pinHash
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

extension Profile: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "profiles"

    public enum Columns: String, ColumnExpression {
        case id, name, role, pinHash, isActive, createdAt
    }
}