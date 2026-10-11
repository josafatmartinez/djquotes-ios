import Foundation
import GRDB

struct QuoteCostItem: Codable {
    var id: String
    var quoteVersionId: String
    var costType: InternalCostType
    var label: String
    var unitCost: String
    var quantity: String
    var totalCost: String
}

extension QuoteCostItem: FetchableRecord, PersistableRecord {
    static let databaseTableName = "quote_cost_items"

    enum Columns: String, ColumnExpression {
        case id, quoteVersionId, costType, label, unitCost, quantity, totalCost
    }
}