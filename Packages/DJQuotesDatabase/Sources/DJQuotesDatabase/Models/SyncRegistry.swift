import Foundation
import GRDB

public struct SyncRegistry: Codable, Identifiable {
    public var id: String
    public var sourceDeviceId: String
    public var targetDeviceId: String
    public var syncCatalog: Bool
    public var syncCustomers: Bool
    public var syncPackages: Bool
    public var enabled: Bool
    public var createdAt: Date

    public init(id: String, sourceDeviceId: String, targetDeviceId: String, syncCatalog: Bool, syncCustomers: Bool, syncPackages: Bool, enabled: Bool, createdAt: Date) {
        self.id = id
        self.sourceDeviceId = sourceDeviceId
        self.targetDeviceId = targetDeviceId
        self.syncCatalog = syncCatalog
        self.syncCustomers = syncCustomers
        self.syncPackages = syncPackages
        self.enabled = enabled
        self.createdAt = createdAt
    }
}

extension SyncRegistry: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "sync_registry"

    public enum Columns: String, ColumnExpression {
        case id, sourceDeviceId, targetDeviceId
        case syncCatalog, syncCustomers, syncPackages
        case enabled, createdAt
    }
}