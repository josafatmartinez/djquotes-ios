import Foundation
import GRDB

struct QuoteItem: Codable {
    var id: String
    var quoteVersionId: String
    var catalogItemId: String?
    var label: String
    var unitPrice: String
    var quantity: String
    var isPackageComponent: Bool
    var showOnQuote: Bool
    var showPriceOnQuote: Bool
    var sortOrder: Int
}

extension QuoteItem: FetchableRecord, PersistableRecord {
    static let databaseTableName = "quote_items"

    enum Columns: String, ColumnExpression {
        case id, quoteVersionId, catalogItemId, label, unitPrice, quantity
        case isPackageComponent, showOnQuote, showPriceOnQuote, sortOrder
    }
}