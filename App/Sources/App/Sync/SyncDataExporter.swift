import Foundation
import GRDB
import DJQuotesDatabase

enum SyncDataExporter {
    static func buildSnapshot() async -> DataSnapshot? {
        do {
            let customers: [DataSnapshot.CustomerSnapshot] = try await DatabaseManager.shared.read { db in
                let rows = try Customer.fetchAll(db)
                return rows.map { DataSnapshot.CustomerSnapshot(id: $0.id, name: $0.name, phone: $0.phone, email: $0.email, createdAt: $0.createdAt) }
            }
            let items: [DataSnapshot.CatalogItemSnapshot] = try await DatabaseManager.shared.read { db in
                let rows = try CatalogItem.fetchAll(db)
                return rows.map { DataSnapshot.CatalogItemSnapshot(id: $0.id, name: $0.name, description: $0.description, type: $0.type.rawValue, salePrice: $0.salePrice, internalCost: $0.internalCost, archived: $0.archived, createdAt: $0.createdAt) }
            }
            let packages: [DataSnapshot.PackageSnapshot] = try await DatabaseManager.shared.read { db in
                let rows = try Package.fetchAll(db)
                return rows.map { DataSnapshot.PackageSnapshot(id: $0.id, name: $0.name, description: $0.description, pricingMode: $0.pricingMode.rawValue, commercialPrice: $0.commercialPrice, manualPrice: $0.manualPrice, suggestedInstallerCount: $0.suggestedInstallerCount, isActive: $0.isActive, createdAt: $0.createdAt) }
            }
            return DataSnapshot(deviceId: UserDefaults.standard.string(forKey: "sync_device_id") ?? "", timestamp: Date(), customers: customers, catalogItems: items, packages: packages)
        } catch {
            return nil
        }
    }
}