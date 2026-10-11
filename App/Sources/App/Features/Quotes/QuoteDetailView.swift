import SwiftUI
import DJQuotesDatabase
import DJQuotesDomain
import GRDB
import DJQuotesDomain

struct QuoteDetailView: View {
    @Environment(AuthManager.self) private var auth
    @Bindable var vm: QuoteViewModel
    let quote: Quote

    @State private var version: QuoteVersion?
    @State private var items: [QuoteItem] = []
    @State private var costItems: [QuoteCostItem] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading { ProgressView() }
            else if let version = version {
                List {
                    Section(String(localized: "quote.detail.header")) {
                        LabeledContent(String(localized: "quote.folio"), value: quote.folio)
                        LabeledContent(String(localized: "quote.status"), value: version.status.displayName)
                        LabeledContent(String(localized: "quote.version"), value: "V\(version.versionNumber)")
                        LabeledContent(String(localized: "quote.createdAt"), value: version.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }

                    Section(String(localized: "quote.items")) {
                        ForEach(items) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.label).font(.subheadline)
                                    Text("Qty: \(item.quantity)").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let unit = Double(item.unitPrice), let qty = Int(item.quantity) {
                                    Text(String(format: "$%.2f", unit * Double(qty))).font(.subheadline)
                                }
                            }
                        }
                    }

                    Section(String(localized: "quote.financial")) {
                        LabeledContent(String(localized: "quote.subtotal"), value: Money(version.subtotal)?.formatted() ?? "$0.00")
                        LabeledContent(String(localized: "quote.travel"), value: Money(version.travelCharge)?.formatted() ?? "$0.00")
                        LabeledContent(String(localized: "quote.discount"), value: "\(version.discount)%")
                        LabeledContent(String(localized: "quote.total"), value: Money(version.total)?.formatted() ?? "$0.00").fontWeight(.bold)
                        LabeledContent(String(localized: "quote.deposit"), value: Money(version.depositAmount)?.formatted() ?? "$0.00")
                        LabeledContent(String(localized: "quote.balance"), value: Money(version.balance)?.formatted() ?? "$0.00").fontWeight(.bold)
                    }

                    if auth.currentProfile?.role == .admin, !costItems.isEmpty {
                        Section(String(localized: "quote.internalCosts")) {
                            ForEach(costItems) { item in
                                HStack {
                                    Text(item.label)
                                    Spacer()
                                    let cost = (Decimal(string: item.unitCost) ?? .zero) * (Decimal(string: item.quantity) ?? 1)
                                    Text(cost.description).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    if let notes = version.customerNotes {
                        Section(String(localized: "quote.notes")) { Text(notes).font(.callout) }
                    }

                    Section {
                        switch version.status {
                        case .draft:
                            Button(String(localized: "quote.send")) { Task { await vm.changeStatus(quote: quote, version: version, to: .sent) } }
                            Button(role: .destructive) { Task { await vm.cancelQuote(quote) } } label: { Text(String(localized: "quote.cancel")) }

                        case .sent:
                            Button(String(localized: "quote.accept")) { Task { await vm.changeStatus(quote: quote, version: version, to: .accepted) } }
                            Button(String(localized: "quote.reject")) { Task { await vm.changeStatus(quote: quote, version: version, to: .rejected) } }

                        default:
                            if !QuoteLifecycle.isTerminal(version.status.rawValue) || version.status == .accepted {
                                Button(String(localized: "quote.revise")) {
                                    Task { await vm.createRevision(quote: quote, version: version, createdBy: auth.currentProfile?.id ?? "") }
                                }
                            }
                        }
                    }
                }
                .navigationTitle(quote.folio)
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        do {
            if let versionId = quote.currentVersionId {
                version = try await DatabaseManager.shared.read { db in
                    try QuoteVersion.fetchOne(db, key: versionId)
                }
                items = try await DatabaseManager.shared.read { db in
                    try QuoteItem.filter(Column("quoteVersionId") == versionId)
                        .order(Column("sortOrder").asc).fetchAll(db)
                }
                if auth.currentProfile?.role == .admin {
                    costItems = try await DatabaseManager.shared.read { db in
                        try QuoteCostItem.filter(Column("quoteVersionId") == versionId).fetchAll(db)
                    }
                }
            }
        } catch {
            vm.error = error.localizedDescription
        }
        isLoading = false
    }
}

extension QuoteStatus {
    var displayName: String {
        switch self {
        case .draft: String(localized: "quote.status.draft")
        case .sent: String(localized: "quote.status.sent")
        case .accepted: String(localized: "quote.status.accepted")
        case .rejected: String(localized: "quote.status.rejected")
        case .expired: String(localized: "quote.status.expired")
        case .cancelled: String(localized: "quote.status.cancelled")
        }
    }
}