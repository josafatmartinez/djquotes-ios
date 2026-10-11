import Foundation
import GRDB

struct WorkerRole: Codable {
    var id: String
    var name: String
    var defaultCost: String
    var costType: WorkerCostType
    var isActive: Bool
}

extension WorkerRole: FetchableRecord, PersistableRecord {
    static let databaseTableName = "worker_roles"

    enum Columns: String, ColumnExpression {
        case id, name, defaultCost, costType, isActive
    }
}