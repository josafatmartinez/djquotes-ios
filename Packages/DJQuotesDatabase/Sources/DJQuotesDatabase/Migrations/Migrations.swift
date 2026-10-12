import Foundation
import GRDB

enum Migrations {
    static func apply(to dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_tables") { db in
            try createProfiles(in: db)
            try createCustomers(in: db)
            try createCatalogItems(in: db)
            try createPackages(in: db)
            try createPackageItems(in: db)
            try createPackageSuggestedExtras(in: db)
            try createWorkerRoles(in: db)
            try createQuotes(in: db)
            try createQuoteVersions(in: db)
            try createQuoteItems(in: db)
            try createQuoteCostItems(in: db)
            try seedWorkerRoles(in: db)
        }

        migrator.registerMigration("v2_remove_roles") { db in
            try db.alter(table: "profiles") { t in
                t.add(column: "deviceId", .text)
            }
            try db.execute(sql: "UPDATE profiles SET deviceId = id WHERE deviceId IS NULL")
            try db.alter(table: "profiles") { t in
                t.add(column: "deviceName", .text)
            }
        }

        migrator.registerMigration("v3_sync_registry") { db in
            try createSyncRegistry(in: db)
        }

        try migrator.migrate(dbQueue)
    }

    private static func createProfiles(in db: Database) throws {
        try db.create(table: "profiles") { t in
            t.primaryKey("id", .text)
            t.column("name", .text).notNull()
            t.column("pinHash", .text).notNull()
            t.column("isActive", .boolean).notNull().defaults(to: true)
            t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
        }
    }

    private static func createCustomers(in db: Database) throws {
        try db.create(table: "customers") { t in
            t.primaryKey("id", .text)
            t.column("name", .text).notNull()
            t.column("phone", .text).notNull()
            t.column("email", .text)
            t.column("createdBy", .text).notNull().references("profiles")
            t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
        }
    }

    private static func createCatalogItems(in db: Database) throws {
        try db.create(table: "catalog_items") { t in
            t.primaryKey("id", .text)
            t.column("name", .text).notNull()
            t.column("description", .text)
            t.column("type", .text).notNull()
            t.column("salePrice", .text).notNull()
            t.column("internalCost", .text)
            t.column("archived", .boolean).notNull().defaults(to: false)
            t.column("createdBy", .text).notNull().references("profiles")
            t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
        }
    }

    private static func createPackages(in db: Database) throws {
        try db.create(table: "packages") { t in
            t.primaryKey("id", .text)
            t.column("name", .text).notNull()
            t.column("description", .text)
            t.column("pricingMode", .text).notNull()
            t.column("commercialPrice", .text)
            t.column("manualPrice", .text)
            t.column("suggestedInstallerCount", .integer).notNull().defaults(to: 0)
            t.column("isActive", .boolean).notNull().defaults(to: true)
            t.column("createdBy", .text).notNull().references("profiles")
            t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
        }
    }

    private static func createPackageItems(in db: Database) throws {
        try db.create(table: "package_items") { t in
            t.primaryKey("id", .text)
            t.column("packageId", .text).notNull().references("packages", onDelete: .cascade)
            t.column("catalogItemId", .text).notNull().references("catalog_items")
            t.column("quantity", .text).notNull()
            t.column("unitPriceOverride", .text)
            t.column("isOptional", .boolean).notNull().defaults(to: false)
            t.column("sortOrder", .integer).notNull().defaults(to: 0)
            t.uniqueKey(["packageId", "catalogItemId"])
        }
    }

    private static func createPackageSuggestedExtras(in db: Database) throws {
        try db.create(table: "package_suggested_extras") { t in
            t.column("packageId", .text).notNull().references("packages", onDelete: .cascade)
            t.column("catalogItemId", .text).notNull().references("catalog_items")
            t.column("sortOrder", .integer).notNull().defaults(to: 0)
            t.primaryKey(["packageId", "catalogItemId"])
        }
    }

    private static func createWorkerRoles(in db: Database) throws {
        try db.create(table: "worker_roles") { t in
            t.primaryKey("id", .text)
            t.column("name", .text).notNull().unique()
            t.column("defaultCost", .text).notNull()
            t.column("costType", .text).notNull()
            t.column("isActive", .boolean).notNull().defaults(to: true)
        }
    }

    private static func createQuotes(in db: Database) throws {
        try db.create(table: "quotes") { t in
            t.primaryKey("id", .text)
            t.column("folio", .text).notNull().unique()
            t.column("customerId", .text).notNull().references("customers")
            t.column("createdBy", .text).notNull().references("profiles")
            t.column("currentVersionId", .text)
            t.column("acceptedVersionId", .text)
            t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
        }
    }

    private static func createQuoteVersions(in db: Database) throws {
        try db.create(table: "quote_versions") { t in
            t.primaryKey("id", .text)
            t.column("quoteId", .text).notNull().references("quotes", onDelete: .cascade)
            t.column("versionNumber", .integer).notNull()
            t.column("status", .text).notNull()
            t.column("sourceMode", .text)
            t.column("sourcePackageId", .text)

            t.column("eventDate", .date)
            t.column("eventName", .text)
            t.column("eventLocation", .text)
            t.column("travelCharge", .text).notNull().defaults(to: "0.00")
            t.column("travelConfirmedAmount", .text)
            t.column("travelConfirmedLocation", .text)

            t.column("subtotal", .text).notNull().defaults(to: "0.00")
            t.column("discount", .text).notNull().defaults(to: "0.00")
            t.column("total", .text).notNull().defaults(to: "0.00")
            t.column("depositAmount", .text).notNull().defaults(to: "0.00")
            t.column("balance", .text).notNull().defaults(to: "0.00")

            t.column("customerNameSnapshot", .text)
            t.column("customerPhoneSnapshot", .text)
            t.column("customerEmailSnapshot", .text)
            t.column("packageNameSnapshot", .text)
            t.column("packagePriceSnapshot", .text)

            t.column("customerNotes", .text)
            t.column("internalNotes", .text)

            t.column("locked", .boolean).notNull().defaults(to: false)
            t.column("lockVersion", .integer).notNull().defaults(to: 1)
            t.column("createdBy", .text).notNull().references("profiles")
            t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            t.column("sentAt", .datetime)

            t.uniqueKey(["quoteId", "versionNumber"])
        }
    }

    private static func createQuoteItems(in db: Database) throws {
        try db.create(table: "quote_items") { t in
            t.primaryKey("id", .text)
            t.column("quoteVersionId", .text).notNull().references("quote_versions", onDelete: .cascade)
            t.column("catalogItemId", .text)
            t.column("label", .text).notNull()
            t.column("unitPrice", .text).notNull()
            t.column("quantity", .text).notNull()
            t.column("isPackageComponent", .boolean).notNull().defaults(to: false)
            t.column("showOnQuote", .boolean).notNull().defaults(to: true)
            t.column("showPriceOnQuote", .boolean).notNull().defaults(to: true)
            t.column("sortOrder", .integer).notNull().defaults(to: 0)
        }
    }

    private static func createQuoteCostItems(in db: Database) throws {
        try db.create(table: "quote_cost_items") { t in
            t.primaryKey("id", .text)
            t.column("quoteVersionId", .text).notNull().references("quote_versions", onDelete: .cascade)
            t.column("costType", .text).notNull()
            t.column("label", .text).notNull()
            t.column("unitCost", .text).notNull()
            t.column("quantity", .text).notNull()
            t.column("totalCost", .text).notNull()
        }
    }

    private static func seedWorkerRoles(in db: Database) throws {
        let installerId = UUID().uuidString
        try db.execute(
            sql: """
                INSERT INTO worker_roles (id, name, defaultCost, costType, isActive)
                VALUES (?, 'Installer', '700.00', 'PER_EVENT', 1)
                ON CONFLICT(name) DO NOTHING
            """,
            arguments: [installerId]
        )
    }

    private static func createSyncRegistry(in db: Database) throws {
        try db.create(table: "sync_registry") { t in
            t.primaryKey("id", .text)
            t.column("sourceDeviceId", .text).notNull()
            t.column("targetDeviceId", .text).notNull()
            t.column("syncCatalog", .boolean).notNull().defaults(to: true)
            t.column("syncCustomers", .boolean).notNull().defaults(to: true)
            t.column("syncPackages", .boolean).notNull().defaults(to: true)
            t.column("enabled", .boolean).notNull().defaults(to: false)
            t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            t.uniqueKey(["sourceDeviceId", "targetDeviceId"])
        }
    }
}