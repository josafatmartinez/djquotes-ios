import Foundation
import GRDB

public struct Package: Codable, Identifiable {
    public var id: String
    public var name: String
    public var description: String?
    public var pricingMode: PackagePricingMode
    public var commercialPrice: String?
    public var manualPrice: String?
    public var suggestedInstallerCount: Int
    public var isActive: Bool
    public var createdBy: String
    public var createdAt: Date
    public init(id: String, name: String, description: String?, pricingMode: PackagePricingMode, commercialPrice: String?, manualPrice: String?, suggestedInstallerCount: Int, isActive: Bool, createdBy: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.description = description
        self.pricingMode = pricingMode
        self.commercialPrice = commercialPrice
        self.manualPrice = manualPrice
        self.suggestedInstallerCount = suggestedInstallerCount
        self.isActive = isActive
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
}

extension Package: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "packages"

    public enum Columns: String, ColumnExpression {
        case id, name, description, pricingMode, commercialPrice, manualPrice, suggestedInstallerCount, isActive, createdBy, createdAt
    }
}