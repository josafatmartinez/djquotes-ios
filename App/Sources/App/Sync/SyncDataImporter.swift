import Foundation
import GRDB
import DJQuotesDatabase

enum SyncDataImporter {
    static func importSnapshot(_ snapshot: DataSnapshot) async {
        do {
            try await DatabaseManager.shared.write { db in
                for c in snapshot.customers {
                    if (try? Customer.fetchOne(db, key: c.id)) != nil { continue }
                    let customer = Customer(id: c.id, name: c.name, phone: c.phone, email: c.email, createdBy: "", createdAt: c.createdAt)
                    try? customer.insert(db)
                }
                for item in snapshot.catalogItems {
                    if (try? CatalogItem.fetchOne(db, key: item.id)) != nil { continue }
                    let catalogItem = CatalogItem(id: item.id, name: item.name, description: item.description, type: CatalogItemType(rawValue: item.type) ?? .service, salePrice: item.salePrice, internalCost: item.internalCost, archived: item.archived, createdBy: "", createdAt: item.createdAt)
                    try? catalogItem.insert(db)
                }
                for pkg in snapshot.packages {
                    if (try? Package.fetchOne(db, key: pkg.id)) != nil { continue }
                    let package = Package(id: pkg.id, name: pkg.name, description: pkg.description, pricingMode: PackagePricingMode(rawValue: pkg.pricingMode) ?? .manual, commercialPrice: pkg.commercialPrice, manualPrice: pkg.manualPrice, suggestedInstallerCount: pkg.suggestedInstallerCount, isActive: pkg.isActive, createdBy: "", createdAt: pkg.createdAt)
                    try? package.insert(db)
                }
            }
        } catch {
            print("[SyncDataImporter] error: \(error)")
        }
    }
}