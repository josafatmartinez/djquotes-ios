import Foundation
import GRDB

public enum CatalogItemType: String, Codable, DatabaseValueConvertible {
    case service = "SERVICE"
    case equipment = "EQUIPMENT"
    case accessory = "ACCESSORY"
    case extra = "EXTRA"
    case consumable = "CONSUMABLE"
}

public enum PackagePricingMode: String, Codable, DatabaseValueConvertible {
    case automatic = "AUTOMATIC"
    case commercial = "COMMERCIAL"
    case manual = "MANUAL"
}

public enum QuoteStatus: String, Codable, DatabaseValueConvertible, CaseIterable {
    case draft = "DRAFT"
    case sent = "SENT"
    case accepted = "ACCEPTED"
    case rejected = "REJECTED"
    case expired = "EXPIRED"
    case cancelled = "CANCELLED"
}

public enum InternalCostType: String, Codable, DatabaseValueConvertible {
    case labor = "LABOR"
    case transport = "TRANSPORT"
    case rental = "RENTAL"
    case consumable = "CONSUMABLE"
    case other = "OTHER"
}

public enum QuoteSourceMode: String, Codable, DatabaseValueConvertible {
    case package = "PACKAGE"
    case scratch = "SCRATCH"
}

public enum WorkerCostType: String, Codable, DatabaseValueConvertible {
    case perEvent = "PER_EVENT"
}