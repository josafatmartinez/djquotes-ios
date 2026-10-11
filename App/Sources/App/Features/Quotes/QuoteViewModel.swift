import Foundation
import SwiftUI
import DJQuotesDatabase
import DJQuotesDomain
import GRDB

// MARK: - Wizard State

enum QuoteWizardStep: Int, CaseIterable {
    case customer = 0
    case eventDetails = 1
    case source = 2
    case customize = 3
    case extras = 4
    case pricing = 5
    case summary = 6

    var title: String {
        switch self {
        case .customer: String(localized: "quote.wizard.customer")
        case .eventDetails: String(localized: "quote.wizard.event")
        case .source: String(localized: "quote.wizard.source")
        case .customize: String(localized: "quote.wizard.customize")
        case .extras: String(localized: "quote.wizard.extras")
        case .pricing: String(localized: "quote.wizard.pricing")
        case .summary: String(localized: "quote.wizard.summary")
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class QuoteViewModel {
    var quotes: [Quote] = []
    var isLoading = false
    var error: String?

    // MARK: - Wizard State

    var wizardStep = QuoteWizardStep.customer
    var selectedCustomer: Customer?
    var eventName = ""
    var eventDate = Date()
    var sourceMode: QuoteSourceMode = .scratch
    var selectedPackage: Package?
    var packageItems: [PackageItem] = []
    var wizardItems: [WizardQuoteItem] = []
    var suggestedExtras: Set<String> = []
    var wizardExtras: [WizardQuoteItem] = []
    var installerCount = 0
    var travelCharge = "0.00"
    var discountRate = "0"
    var depositAmount = "0.00"
    var customerNotes = ""
    var internalNotes = ""

    var isSaving = false
    var editingQuote: Quote?
    var editingVersion: QuoteVersion?

    // Navigation
    var showEditor = false
    var selectedQuoteDetail: Quote?

    // MARK: - Computed

    var subtotal: Money {
        PricingEngine.calculateSubtotal(items: wizardItems.map {
            (unitPrice: Money($0.unitPrice) ?? .zero,
             quantity: Int($0.quantity) ?? 1)
        })
    }

    var extrasSubtotal: Money {
        PricingEngine.calculateSubtotal(items: wizardExtras.map {
            (unitPrice: Money($0.unitPrice) ?? .zero,
             quantity: Int($0.quantity) ?? 1)
        })
    }

    var quotedTotal: Money {
        PricingEngine.calculateTotal(
            subtotal: subtotal,
            extrasSubtotal: extrasSubtotal,
            travelCharge: Money(travelCharge) ?? .zero,
            discountRate: Decimal(string: discountRate) ?? .zero
        )
    }

    var quotedBalance: Money {
        PricingEngine.calculateBalance(
            total: quotedTotal,
            depositAmount: Money(depositAmount) ?? .zero
        )
    }

    var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    // MARK: - Quote List

    func loadQuotes() async {
        isLoading = true
        do {
            quotes = try await DatabaseManager.shared.read { db in
                try Quote.order(Column("createdAt").desc).fetchAll(db)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Wizard Actions

    func startNewQuote(customer: Customer? = nil) {
        resetWizard()
        selectedCustomer = customer
        wizardStep = customer != nil ? .eventDetails : .customer
        editingQuote = nil
        editingVersion = nil
        showEditor = true
    }

    func startEditing(quote: Quote, version: QuoteVersion) {
        resetWizard()
        editingQuote = quote
        editingVersion = version
        selectedCustomer = nil
        // TODO: Load existing data from version
        showEditor = true
    }

    func selectPackage(_ package: Package) {
        selectedPackage = package
        sourceMode = .package
        wizardItems.removeAll()
        suggestedExtras.removeAll()
        Task {
            do {
                let items = try await DatabaseManager.shared.read { db in
                    try PackageItem
                        .filter(PackageItem.Columns.packageId == package.id)
                        .order(PackageItem.Columns.sortOrder.asc)
                        .fetchAll(db)
                }
                packageItems = items
                wizardItems = items.map {
                    WizardQuoteItem(
                        catalogItemId: $0.catalogItemId,
                        label: "",
                        unitPrice: $0.unitPriceOverride ?? "0.00",
                        quantity: $0.quantity,
                        isOptional: $0.isOptional
                    )
                }
                let extras = try await DatabaseManager.shared.read { db in
                    try PackageSuggestedExtra
                        .filter(PackageSuggestedExtra.Columns.packageId == package.id)
                        .order(PackageSuggestedExtra.Columns.sortOrder.asc)
                        .fetchAll(db)
                }
                suggestedExtras = Set(extras.map(\.catalogItemId))
            } catch {}
        }
        wizardStep = .customize
    }

    func saveDraft(createdBy: String) async -> Bool {
        isSaving = true
        defer { isSaving = false }

        let quoteId = editingQuote?.id ?? UUID().uuidString
        let versionId = editingVersion?.id ?? UUID().uuidString

        do {
            try await DatabaseManager.shared.write { [self] db in
                let folio: String
                if let existing = editingQuote {
                    folio = existing.folio
                } else {
                    let allNumbers = try Quote.fetchAll(db).compactMap { q -> Int? in
                        let parts = q.folio.split(separator: "-")
                        guard parts.count == 3, let n = Int(parts[2]) else { return nil }
                        return n
                    }
                    let next = QuoteFolioGenerator.nextQuoteNumber(existingNumbers: allNumbers)
                    folio = QuoteFolioGenerator.generate(year: Calendar.current.component(.year, from: Date()), number: next)
                }

                let total = quotedTotal
                let balance = quotedBalance

                let version = QuoteVersion(
                    id: versionId,
                    quoteId: quoteId,
                    versionNumber: editingVersion?.versionNumber ?? 1,
                    status: editingVersion?.status ?? .draft,
                    sourceMode: sourceMode,
                    sourcePackageId: selectedPackage?.id,
                    eventDate: eventDate,
                    eventName: eventName.isEmpty ? nil : eventName,
                    eventLocation: nil,
                    travelCharge: travelCharge,
                    travelConfirmedAmount: nil,
                    travelConfirmedLocation: nil,
                    subtotal: subtotal.formattedPlain(),
                    discount: discountRate,
                    total: total.formattedPlain(),
                    depositAmount: depositAmount,
                    balance: balance.formattedPlain(),
                    customerNameSnapshot: selectedCustomer?.name,
                    customerPhoneSnapshot: selectedCustomer?.phone,
                    customerEmailSnapshot: selectedCustomer?.email,
                    packageNameSnapshot: selectedPackage?.name,
                    packagePriceSnapshot: nil,
                    customerNotes: customerNotes.isEmpty ? nil : customerNotes,
                    internalNotes: internalNotes.isEmpty ? nil : internalNotes,
                    locked: false,
                    lockVersion: editingVersion?.lockVersion ?? 1,
                    createdBy: createdBy,
                    createdAt: editingVersion?.createdAt ?? Date(),
                    sentAt: nil
                )

                if editingQuote == nil {
                    let quote = Quote(
                        id: quoteId,
                        folio: folio,
                        customerId: selectedCustomer?.id ?? "",
                        createdBy: createdBy,
                        currentVersionId: versionId,
                        acceptedVersionId: nil,
                        createdAt: Date()
                    )
                    try quote.insert(db)
                    editingQuote = quote
                } else {
                    var q = editingQuote!
                    q.currentVersionId = versionId
                    try q.update(db)
                }

                if editingVersion == nil {
                    try version.insert(db)
                } else {
                    try version.update(db)
                }

                try QuoteItem.filter(QuoteItem.Columns.quoteVersionId == versionId).deleteAll(db)
                for (idx, item) in wizardItems.enumerated() {
                    let qi = QuoteItem(
                        id: UUID().uuidString,
                        quoteVersionId: versionId,
                        catalogItemId: (item.catalogItemId ?? "").isEmpty ? nil : item.catalogItemId,
                        label: item.label.isEmpty ? "Item" : item.label,
                        unitPrice: item.unitPrice,
                        quantity: item.quantity,
                        isPackageComponent: sourceMode == .package,
                        showOnQuote: true,
                        showPriceOnQuote: true,
                        sortOrder: idx
                    )
                    try qi.insert(db)
                }
                for (idx, item) in wizardExtras.enumerated() {
                    let qi = QuoteItem(
                        id: UUID().uuidString,
                        quoteVersionId: versionId,
                        catalogItemId: (item.catalogItemId ?? "").isEmpty ? nil : item.catalogItemId,
                        label: item.label.isEmpty ? "Extra" : item.label,
                        unitPrice: item.unitPrice,
                        quantity: item.quantity,
                        isPackageComponent: false,
                        showOnQuote: true,
                        showPriceOnQuote: true,
                        sortOrder: wizardItems.count + idx
                    )
                    try qi.insert(db)
                }

                editingVersion = version
            }
            showEditor = false
            await loadQuotes()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func sendQuote() async -> Bool {
        guard let quote = editingQuote,
              let version = editingVersion,
              version.status == .draft,
              QuoteLifecycle.canTransition(from: "DRAFT", to: "SENT") else {
            error = String(localized: "quote.error.cannotSend")
            return false
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await DatabaseManager.shared.write { [self] db in
                var v = version
                v.status = .sent
                v.locked = true
                v.sentAt = Date()
                try v.update(db)
            }
            showEditor = false
            await loadQuotes()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func changeStatus(quote: Quote, version: QuoteVersion, to newStatus: QuoteStatus) async -> Bool {
        guard QuoteLifecycle.canTransition(from: version.status.rawValue, to: newStatus.rawValue) else {
            error = String(localized: "quote.error.invalidTransition")
            return false
        }
        do {
            try await DatabaseManager.shared.write { [self] db in
                var v = version
                v.status = newStatus
                v.locked = QuoteLifecycle.isImmutable(newStatus.rawValue)
                try v.update(db)
                if newStatus == .accepted {
                    var q = quote
                    q.acceptedVersionId = version.id
                    try q.update(db)
                }
            }
            await loadQuotes()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func createRevision(quote: Quote, version: QuoteVersion, createdBy: String) async -> Bool {
        let newNumber = version.versionNumber + 1
        let newVersionId = UUID().uuidString
        do {
            try await DatabaseManager.shared.write { db in
                let revision = QuoteVersion(
                    id: newVersionId,
                    quoteId: quote.id,
                    versionNumber: newNumber,
                    status: .draft,
                    sourceMode: version.sourceMode,
                    sourcePackageId: version.sourcePackageId,
                    eventDate: version.eventDate,
                    eventName: version.eventName,
                    eventLocation: version.eventLocation,
                    travelCharge: version.travelCharge,
                    travelConfirmedAmount: nil,
                    travelConfirmedLocation: nil,
                    subtotal: version.subtotal,
                    discount: version.discount,
                    total: version.total,
                    depositAmount: version.depositAmount,
                    balance: version.balance,
                    customerNameSnapshot: version.customerNameSnapshot,
                    customerPhoneSnapshot: version.customerPhoneSnapshot,
                    customerEmailSnapshot: version.customerEmailSnapshot,
                    packageNameSnapshot: version.packageNameSnapshot,
                    packagePriceSnapshot: version.packagePriceSnapshot,
                    customerNotes: version.customerNotes,
                    internalNotes: version.internalNotes,
                    locked: false,
                    lockVersion: 1,
                    createdBy: createdBy,
                    createdAt: Date(),
                    sentAt: nil
                )
                try revision.insert(db)
                var q = quote
                q.currentVersionId = newVersionId
                try q.update(db)

                let items = try QuoteItem.filter(QuoteItem.Columns.quoteVersionId == version.id).fetchAll(db)
                for item in items {
                    var copy = item
                    copy.id = UUID().uuidString
                    copy.quoteVersionId = newVersionId
                    try copy.insert(db)
                }
            }
            await loadQuotes()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func cancelQuote(_ quote: Quote) async {
        guard let versionId = quote.currentVersionId else { return }
        do {
            try await DatabaseManager.shared.write { db in
                if let version = try QuoteVersion.fetchOne(db, key: versionId),
                   version.status == .draft {
                    var v = version
                    v.status = .cancelled
                    v.locked = true
                    try v.update(db)
                }
            }
            await loadQuotes()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Helpers

    func resetWizard() {
        wizardStep = .customer
        selectedCustomer = nil
        eventName = ""
        eventDate = Date()
        sourceMode = .scratch
        selectedPackage = nil
        wizardItems = []
        wizardExtras = []
        suggestedExtras = []
        installerCount = 0
        travelCharge = "0.00"
        discountRate = "0"
        depositAmount = "0.00"
        customerNotes = ""
        internalNotes = ""
        packageItems = []
    }

    func addItem(label: String, unitPrice: String, quantity: String) {
        wizardItems.append(WizardQuoteItem(
            catalogItemId: nil,
            label: label,
            unitPrice: unitPrice,
            quantity: quantity,
            isOptional: false
        ))
    }

    func addExtra(label: String, unitPrice: String, quantity: String) {
        wizardExtras.append(WizardQuoteItem(
            catalogItemId: nil,
            label: label,
            unitPrice: unitPrice,
            quantity: quantity,
            isOptional: false
        ))
    }

    func removeItem(at index: Int) { wizardItems.remove(at: index) }
    func removeExtra(at index: Int) { wizardExtras.remove(at: index) }
}

// MARK: - Wizard Quote Item

struct WizardQuoteItem: Identifiable {
    let id = UUID()
    var catalogItemId: String?
    var label: String
    var unitPrice: String
    var quantity: String
    var isOptional: Bool
}