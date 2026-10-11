import Foundation
import GRDB

struct QuoteVersion: Codable {
    var id: String
    var quoteId: String
    var versionNumber: Int
    var status: QuoteStatus
    var sourceMode: QuoteSourceMode?
    var sourcePackageId: String?

    var eventDate: Date?
    var eventName: String?
    var eventLocation: String?
    var travelCharge: String
    var travelConfirmedAmount: String?
    var travelConfirmedLocation: String?

    var subtotal: String
    var discount: String
    var total: String
    var depositAmount: String
    var balance: String

    var customerNameSnapshot: String?
    var customerPhoneSnapshot: String?
    var customerEmailSnapshot: String?
    var packageNameSnapshot: String?
    var packagePriceSnapshot: String?

    var customerNotes: String?
    var internalNotes: String?

    var locked: Bool
    var lockVersion: Int
    var createdBy: String
    var createdAt: Date
    var sentAt: Date?
}

extension QuoteVersion: FetchableRecord, PersistableRecord {
    static let databaseTableName = "quote_versions"

    enum Columns: String, ColumnExpression {
        case id, quoteId, versionNumber, status, sourceMode, sourcePackageId
        case eventDate, eventName, eventLocation
        case travelCharge, travelConfirmedAmount, travelConfirmedLocation
        case subtotal, discount, total, depositAmount, balance
        case customerNameSnapshot, customerPhoneSnapshot, customerEmailSnapshot
        case packageNameSnapshot, packagePriceSnapshot
        case customerNotes, internalNotes
        case locked, lockVersion, createdBy, createdAt, sentAt
    }
}