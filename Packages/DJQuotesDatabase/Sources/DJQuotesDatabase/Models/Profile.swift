import Foundation
import GRDB

public struct Profile: Codable, Hashable, Identifiable {
    public var id: String
    public var name: String
    public var pinHash: String
    public var isActive: Bool
    public var deviceId: String?
    public var deviceName: String?
    public var createdAt: Date

    public init(id: String, name: String, pinHash: String, isActive: Bool, deviceId: String?, deviceName: String?, createdAt: Date) {
        self.id = id
        self.name = name
        self.pinHash = pinHash
        self.isActive = isActive
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.createdAt = createdAt
    }
}

extension Profile: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "profiles"

    public enum Columns: String, ColumnExpression {
        case id, name, pinHash, isActive, deviceId, deviceName, createdAt
    }
}