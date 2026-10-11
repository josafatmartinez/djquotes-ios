import Foundation
import DJQuotesDatabase
import GRDB

@MainActor
@Observable
final class PackageViewModel {
    var packages: [Package] = []
    var packageItems: [String: [PackageItem]] = [:]
    var packageExtras: [String: [PackageSuggestedExtra]] = [:]
    var catalogItems: [CatalogItem] = []
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        do {
            packages = try await DatabaseManager.shared.read { db in
                try Package.order(Package.Columns.name.asc).fetchAll(db)
            }
            catalogItems = try await DatabaseManager.shared.read { db in
                try CatalogItem.filter(CatalogItem.Columns.archived == false)
                    .order(CatalogItem.Columns.name.asc).fetchAll(db)
            }
            for pkg in packages {
                packageItems[pkg.id] = try await DatabaseManager.shared.read { db in
                    try PackageItem.filter(PackageItem.Columns.packageId == pkg.id)
                        .order(PackageItem.Columns.sortOrder.asc).fetchAll(db)
                }
                packageExtras[pkg.id] = try await DatabaseManager.shared.read { db in
                    try PackageSuggestedExtra.filter(PackageSuggestedExtra.Columns.packageId == pkg.id)
                        .order(PackageSuggestedExtra.Columns.sortOrder.asc).fetchAll(db)
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func save(
        existingId: String?,
        name: String,
        pricingMode: PackagePricingMode,
        description: String?,
        items: [(catalogItemId: String, quantity: String, unitPriceOverride: String?, isOptional: Bool)],
        extraItemIds: [String],
        createdBy: String
    ) async -> Bool {
        let packageId = existingId ?? UUID().uuidString
        do {
            try await DatabaseManager.shared.write { db in
                if existingId != nil {
                    var pkg = try Package.fetchOne(db, key: packageId)!
                    pkg.name = name
                    pkg.description = description
                    pkg.pricingMode = pricingMode
                    try pkg.update(db)
                    try PackageItem.filter(PackageItem.Columns.packageId == packageId).deleteAll(db)
                    try PackageSuggestedExtra.filter(PackageSuggestedExtra.Columns.packageId == packageId).deleteAll(db)
                } else {
                    let pkg = Package(
                        id: packageId,
                        name: name,
                        description: description,
                        pricingMode: pricingMode,
                        commercialPrice: nil,
                        manualPrice: nil,
                        suggestedInstallerCount: 0,
                        isActive: true,
                        createdBy: createdBy,
                        createdAt: Date()
                    )
                    try pkg.insert(db)
                }
                for (idx, item) in items.enumerated() {
                    let pkgItem = PackageItem(
                        id: UUID().uuidString,
                        packageId: packageId,
                        catalogItemId: item.catalogItemId,
                        quantity: item.quantity,
                        unitPriceOverride: item.unitPriceOverride,
                        isOptional: item.isOptional,
                        sortOrder: idx
                    )
                    try pkgItem.insert(db)
                }
                for (idx, extraId) in extraItemIds.enumerated() {
                    let extra = PackageSuggestedExtra(
                        packageId: packageId,
                        catalogItemId: extraId,
                        sortOrder: idx
                    )
                    try extra.insert(db)
                }
            }
            await load()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func duplicate(_ package: Package) async {
        do {
            try await DatabaseManager.shared.write { db in
                let newId = UUID().uuidString
                let newPkg = Package(
                    id: newId,
                    name: package.name + " — Copia",
                    description: package.description,
                    pricingMode: package.pricingMode,
                    commercialPrice: package.commercialPrice,
                    manualPrice: package.manualPrice,
                    suggestedInstallerCount: package.suggestedInstallerCount,
                    isActive: true,
                    createdBy: package.createdBy,
                    createdAt: Date()
                )
                try newPkg.insert(db)
                let items = try PackageItem.filter(PackageItem.Columns.packageId == package.id).fetchAll(db)
                for item in items {
                    var copy = item
                    copy.id = UUID().uuidString
                    copy.packageId = newId
                    try copy.insert(db)
                }
                let extras = try PackageSuggestedExtra.filter(PackageSuggestedExtra.Columns.packageId == package.id).fetchAll(db)
                for extra in extras {
                    var copy = extra
                    copy.packageId = newId
                    try copy.insert(db)
                }
            }
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleActive(_ package: Package) async {
        do {
            try await DatabaseManager.shared.write { db in
                var pkg = package; pkg.isActive.toggle(); try pkg.update(db)
            }
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}