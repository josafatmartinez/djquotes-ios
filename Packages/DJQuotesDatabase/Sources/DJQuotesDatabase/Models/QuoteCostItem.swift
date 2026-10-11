import Foundation
import GRDB

public struct QuoteCostItem: Codable, Identifiable {
    public var id: String
    public var quoteVersionId: String
    public var costType: InternalCostType
    public var label: String
    public var unitCost: String
    public var quantity: String
    public var totalCost: String
    public init(id: String, quoteVersionId: String, costType: InternalCostType, label: String, unitCost: String, quantity: String, totalCost: String) {
        self.id = id
        self.quoteVersionId = quoteVersionId
        self.costType = costType
        self.label = label
        self.unitCost = unitCost
        self.quantity = quantity
        self.totalCost = totalCost
    }
}

extension QuoteCostItem: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "quote_cost_items"

    public enum Columns: String, ColumnExpression {
        case id, quoteVersionId, costType, label, unitCost, quantity, totalCost
    }
}