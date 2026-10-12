import SwiftUI
import DJQuotesDatabase
import DJQuotesDomain
import GRDB

struct QuoteListFullView: View {
    @Environment(AuthManager.self) private var auth
    @State private var vm = QuoteViewModel()
    @State private var showEditor = false
    @State private var filterStatus: QuoteStatus?

    var filteredQuotes: [Quote] {
        guard let status = filterStatus else { return vm.quotes }
        return vm.quotes.filter { quote in
            vm.quoteStatusMap[quote.id] == status
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                } else if vm.quotes.isEmpty {
                    ContentUnavailableView(
                        String(localized: "quotes.empty"),
                        systemImage: "doc.text",
                        description: Text("quotes.emptyDescription")
                    )
                } else {
                    VStack(spacing: 0) {
                        Picker("Status", selection: $filterStatus) {
                            Text("All").tag(nil as QuoteStatus?)
                            ForEach(QuoteStatus.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status as QuoteStatus?)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        if filteredQuotes.isEmpty {
                            Spacer()
                            ContentUnavailableView(
                                String(localized: "quote.status.draft"),
                                systemImage: "magnifyingglass",
                                description: Text("No quotes match this filter")
                            )
                            Spacer()
                        } else {
                            List {
                                ForEach(filteredQuotes) { quote in
                                    Button { vm.selectedQuoteDetail = quote } label: {
                                        QuoteListRow(quote: quote, vm: vm)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("tab.quotes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { vm.startNewQuote() } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(item: $vm.selectedQuoteDetail) { quote in
                QuoteDetailView(vm: vm, quote: quote)
            }
            .sheet(isPresented: $showEditor) {
                QuoteEditorView(vm: vm)
            }
        }
        .task { await vm.loadQuotes() }
        .onChange(of: vm.showEditor) { _, new in
            showEditor = new
        }
    }
}

struct QuoteListRow: View {
    let quote: Quote
    let vm: QuoteViewModel

    var statusDisplay: String? {
        guard let status = vm.quoteStatusMap[quote.id] else { return nil }
        return status.displayName
    }

    var statusColor: Color? {
        guard let status = vm.quoteStatusMap[quote.id] else { return nil }
        switch status {
        case .draft: return .secondary
        case .sent: return .blue
        case .accepted: return .green
        case .rejected: return .red
        case .expired: return .orange
        case .cancelled: return .red
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(quote.folio).font(.headline).fontDesign(.monospaced)
                HStack(spacing: 6) {
                    Text(quote.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption).foregroundStyle(.secondary)
                    if let status = statusDisplay, let color = statusColor {
                        Text(status)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color.opacity(0.15))
                            .foregroundStyle(color)
                            .clipShape(.capsule)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}