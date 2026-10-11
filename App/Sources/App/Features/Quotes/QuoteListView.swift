import SwiftUI
import DJQuotesDatabase
import DJQuotesDomain

struct QuoteListFullView: View {
    @Environment(AuthManager.self) private var auth
    @State private var vm = QuoteViewModel()
    @State private var showEditor = false

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
                    List {
                        ForEach(vm.quotes) { quote in
                            Button { vm.selectedQuoteDetail = quote } label: {
                                QuoteListRow(quote: quote)
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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(quote.folio).font(.headline).fontDesign(.monospaced)
                Text("V\(quote.currentVersionId ?? "-")").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(quote.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}