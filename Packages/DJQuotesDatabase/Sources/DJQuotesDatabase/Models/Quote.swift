import Foundation
import GRDB

public struct Quote: Codable, Hashable, Identifiable {
    public var id: String
    public var folio: String
    public var customerId: String
    public var createdBy: String
    public var currentVersionId: String?
    public var acceptedVersionId: String?
    public var createdAt: Date
    public init(id: String, folio: String, customerId: String, createdBy: String, currentVersionId: String?, acceptedVersionId: String?, createdAt: Date) {
        self.id = id
        self.folio = folio
        self.customerId = customerId
        self.createdBy = createdBy
        self.currentVersionId = currentVersionId
        self.acceptedVersionId = acceptedVersionId
        self.createdAt = createdAt
    }
}

extension Quote: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "quotes"

    public enum Columns: String, ColumnExpression {
        case id, folio, customerId, createdBy, currentVersionId, acceptedVersionId, createdAt
    }

    static let customer = belongsTo(Customer.self)
    var customer: QueryInterfaceRequest<Customer> {
        request(for: Quote.customer)
    }
}