import Foundation
import GRDB

public struct QuoteVersion: Codable, Identifiable {
    public var id: String
    public var quoteId: String
    public var versionNumber: Int
    public var status: QuoteStatus
    public var sourceMode: QuoteSourceMode?
    public var sourcePackageId: String?

    public var eventDate: Date?
    public var eventName: String?
    public var eventLocation: String?
    public var travelCharge: String
    public var travelConfirmedAmount: String?
    public var travelConfirmedLocation: String?

    public var subtotal: String
    public var discount: String
    public var total: String
    public var depositAmount: String
    public var balance: String

    public var customerNameSnapshot: String?
    public var customerPhoneSnapshot: String?
    public var customerEmailSnapshot: String?
    public var packageNameSnapshot: String?
    public var packagePriceSnapshot: String?

    public var customerNotes: String?
    public var internalNotes: String?

    public var locked: Bool
    public var lockVersion: Int
    public var createdBy: String
    public var createdAt: Date
    public var sentAt: Date?
    public init(id: String, quoteId: String, versionNumber: Int, status: QuoteStatus, sourceMode: QuoteSourceMode?, sourcePackageId: String?, eventDate: Date?, eventName: String?, eventLocation: String?, travelCharge: String, travelConfirmedAmount: String?, travelConfirmedLocation: String?, subtotal: String, discount: String, total: String, depositAmount: String, balance: String, customerNameSnapshot: String?, customerPhoneSnapshot: String?, customerEmailSnapshot: String?, packageNameSnapshot: String?, packagePriceSnapshot: String?, customerNotes: String?, internalNotes: String?, locked: Bool, lockVersion: Int, createdBy: String, createdAt: Date, sentAt: Date?) {
        self.id = id
        self.quoteId = quoteId
        self.versionNumber = versionNumber
        self.status = status
        self.sourceMode = sourceMode
        self.sourcePackageId = sourcePackageId
        self.eventDate = eventDate
        self.eventName = eventName
        self.eventLocation = eventLocation
        self.travelCharge = travelCharge
        self.travelConfirmedAmount = travelConfirmedAmount
        self.travelConfirmedLocation = travelConfirmedLocation
        self.subtotal = subtotal
        self.discount = discount
        self.total = total
        self.depositAmount = depositAmount
        self.balance = balance
        self.customerNameSnapshot = customerNameSnapshot
        self.customerPhoneSnapshot = customerPhoneSnapshot
        self.customerEmailSnapshot = customerEmailSnapshot
        self.packageNameSnapshot = packageNameSnapshot
        self.packagePriceSnapshot = packagePriceSnapshot
        self.customerNotes = customerNotes
        self.internalNotes = internalNotes
        self.locked = locked
        self.lockVersion = lockVersion
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.sentAt = sentAt
    }
}

extension QuoteVersion: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "quote_versions"

    public enum Columns: String, ColumnExpression {
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