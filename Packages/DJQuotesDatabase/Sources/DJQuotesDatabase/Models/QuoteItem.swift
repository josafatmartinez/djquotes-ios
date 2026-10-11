import Foundation
import GRDB

public struct QuoteItem: Codable, Identifiable {
    public var id: String
    public var quoteVersionId: String
    public var catalogItemId: String?
    public var label: String
    public var unitPrice: String
    public var quantity: String
    public var isPackageComponent: Bool
    public var showOnQuote: Bool
    public var showPriceOnQuote: Bool
    public var sortOrder: Int
    public init(id: String, quoteVersionId: String, catalogItemId: String?, label: String, unitPrice: String, quantity: String, isPackageComponent: Bool, showOnQuote: Bool, showPriceOnQuote: Bool, sortOrder: Int) {
        self.id = id
        self.quoteVersionId = quoteVersionId
        self.catalogItemId = catalogItemId
        self.label = label
        self.unitPrice = unitPrice
        self.quantity = quantity
        self.isPackageComponent = isPackageComponent
        self.showOnQuote = showOnQuote
        self.showPriceOnQuote = showPriceOnQuote
        self.sortOrder = sortOrder
    }
}

extension QuoteItem: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "quote_items"

    public enum Columns: String, ColumnExpression {
        case id, quoteVersionId, catalogItemId, label, unitPrice, quantity
        case isPackageComponent, showOnQuote, showPriceOnQuote, sortOrder
    }
}