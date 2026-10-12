import SwiftUI
import DJQuotesDatabase
import DJQuotesDomain
import DJQuotesPDF
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
    @State private var showShareSheet = false
    @State private var pdfData: Data?

    var body: some View {
        Group {
            if isLoading { ProgressView() }
            else if let version = version {
                List {
                    Section(String(localized: "quote.detail.header")) {
                        LabeledContent(String(localized: "quote.folio"), value: quote.folio)
                        LabeledContent(String(localized: "quote.status")) {
                        Text(version.status.displayName)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(version.status.color.opacity(0.15))
                            .foregroundStyle(version.status.color)
                            .clipShape(.capsule)
                    }
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

                    if !costItems.isEmpty {
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
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                generatePDF()
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                    .sheet(isPresented: $showShareSheet) {
                        if let data = pdfData {
                            ShareSheetView(items: [data])
                        }
                    }
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func generatePDF() {
        guard let v = version else { return }
        let extras = items.filter { !$0.isPackageComponent && ($0.label.lowercased().contains("extra") || !$0.showOnQuote) }
        let mainItems = items.filter { $0 != nil && $0.showOnQuote && $0.isPackageComponent }
        let allItems = items.filter { $0 != nil && $0.showOnQuote }

        let itemTuples = allItems.map { (label: $0.label, quantity: $0.quantity, unitPrice: $0.unitPrice) }

        pdfData = QuotePDFGenerator.generate(
            folio: quote.folio,
            customerName: v.customerNameSnapshot ?? "",
            customerPhone: v.customerPhoneSnapshot ?? "",
            customerEmail: v.customerEmailSnapshot,
            eventName: v.eventName,
            eventDate: v.eventDate?.formatted(date: .long, time: .omitted),
            items: itemTuples,
            extras: [],
            subtotal: v.subtotal,
            extrasSubtotal: "0",
            discount: v.discount,
            travelCharge: v.travelCharge,
            total: v.total,
            deposit: v.depositAmount,
            balance: v.balance,
            notes: v.customerNotes,
            generatedAt: Date()
        )
        showShareSheet = true
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
                costItems = try await DatabaseManager.shared.read { db in
                    try QuoteCostItem.filter(Column("quoteVersionId") == versionId).fetchAll(db)
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
    var color: Color {
        switch self {
        case .draft: .secondary
        case .sent: .blue
        case .accepted: .green
        case .rejected: .red
        case .expired: .orange
        case .cancelled: .red
        }
    }
}

import UIKit

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}