import Foundation
import GRDB

public struct WorkerRole: Codable, Identifiable {
    public var id: String
    public var name: String
    public var defaultCost: String
    public var costType: WorkerCostType
    public var isActive: Bool
    public init(id: String, name: String, defaultCost: String, costType: WorkerCostType, isActive: Bool) {
        self.id = id
        self.name = name
        self.defaultCost = defaultCost
        self.costType = costType
        self.isActive = isActive
    }
}

extension WorkerRole: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "worker_roles"

    public enum Columns: String, ColumnExpression {
        case id, name, defaultCost, costType, isActive
    }
}