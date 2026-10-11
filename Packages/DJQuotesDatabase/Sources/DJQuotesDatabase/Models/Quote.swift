import Foundation
import GRDB

struct Quote: Codable {
    var id: String
    var folio: String
    var customerId: String
    var createdBy: String
    var currentVersionId: String?
    var acceptedVersionId: String?
    var createdAt: Date
}

extension Quote: FetchableRecord, PersistableRecord {
    static let databaseTableName = "quotes"

    enum Columns: String, ColumnExpression {
        case id, folio, customerId, createdBy, currentVersionId, acceptedVersionId, createdAt
    }

    static let customer = belongsTo(Customer.self)
    var customer: QueryInterfaceRequest<Customer> {
        request(for: Quote.customer)
    }
}