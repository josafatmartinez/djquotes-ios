import GRDB
import DJQuotesDatabase
import SwiftUI

struct AuthGateView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        Group {
            if auth.isAuthenticated, auth.currentProfile != nil {
                MainTabView()
            } else {
                ProfilePickerView()
            }
        }
    }
}

struct MainTabView: View {
    @Environment(AuthManager.self) private var auth
    @State private var tab = AppTab.dashboard

    var body: some View {
        TabView(selection: $tab) {
            DashboardView().tabItem { Label(AppTab.dashboard.label, systemImage: AppTab.dashboard.icon) }.tag(AppTab.dashboard)
            CustomerListView().tabItem { Label(AppTab.customers.label, systemImage: AppTab.customers.icon) }.tag(AppTab.customers)
            QuoteListView().tabItem { Label(AppTab.quotes.label, systemImage: AppTab.quotes.icon) }.tag(AppTab.quotes)
            CatalogView().tabItem { Label(AppTab.catalog.label, systemImage: AppTab.catalog.icon) }.tag(AppTab.catalog)
            SettingsView().tabItem { Label(AppTab.settings.label, systemImage: AppTab.settings.icon) }.tag(AppTab.settings)
        }
    }
}

struct DashboardView: View {
    @State private var vm = DashboardViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            summaryCards
                            recentQuotes
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("tab.dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        vm.showNewQuote = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $vm.showNewQuote) {
                QuoteEditorView(vm: vm.quoteVM)
            }
        }
        .task { await vm.load() }
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DashboardCard(title: "quote.status.draft", count: vm.draftCount, color: .secondary, icon: "doc.text")
            DashboardCard(title: "quote.status.sent", count: vm.sentCount, color: .blue, icon: "envelope")
            DashboardCard(title: "quote.status.accepted", count: vm.acceptedCount, color: .green, icon: "checkmark.seal")
            DashboardCard(title: "quote.status.expired", count: vm.expiredCount, color: .orange, icon: "clock.badge.exclamationmark")
        }
    }

    private var recentQuotes: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !vm.recentQuotes.isEmpty {
                Text("Recent quotes")
                    .font(.headline)

                ForEach(vm.recentQuotes) { quote in
                    NavigationLink {
                        QuoteDetailView(vm: vm.quoteVM, quote: quote)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(quote.folio)
                                    .font(.subheadline)
                                    .fontDesign(.monospaced)
                                    .foregroundStyle(.primary)
                                Text(quote.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }
}

struct DashboardCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
            Text(LocalizedStringKey(title))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

@MainActor
@Observable
final class DashboardViewModel {
    var draftCount = 0
    var sentCount = 0
    var acceptedCount = 0
    var expiredCount = 0
    var recentQuotes: [Quote] = []
    var isLoading = true
    var showNewQuote = false
    let quoteVM = QuoteViewModel()

    func load() async {
        isLoading = true
        do {
            let counts = try await DatabaseManager.shared.read { db -> [String: Int] in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT qv.status, COUNT(DISTINCT q.id) as cnt
                    FROM quotes q
                    JOIN quote_versions qv ON qv.id = q.currentVersionId
                    GROUP BY qv.status
                """)
                var map: [String: Int] = [:]
                for row in rows {
                    map[row["status"] as String] = row["cnt"] as Int
                }
                return map
            }
            draftCount = counts["DRAFT"] ?? 0
            sentCount = counts["SENT"] ?? 0
            acceptedCount = counts["ACCEPTED"] ?? 0
            expiredCount = counts["EXPIRED"] ?? 0

            recentQuotes = try await DatabaseManager.shared.read { db in
                try Quote.order(Column("createdAt").desc).limit(5).fetchAll(db)
            }
        } catch {
            _ = error
        }
        isLoading = false
    }
}
struct CustomerListView: View { var body: some View { CustomerListFullView() } }
struct QuoteListView: View { var body: some View { QuoteListFullView() } }
struct CatalogView: View { var body: some View { CatalogListView() } }

struct SettingsView: View {
    @Environment(AuthManager.self) private var auth
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let p = auth.currentProfile {
                        HStack { Text(p.name); Spacer() }
                    }
                    NavigationLink(String(localized: "auth.profiles")) { ProfileListView() }
                    NavigationLink(String(localized: "tab.packages")) { PackageListView() }
                    NavigationLink(String(localized: "settings.workerRoles")) { WorkerRolesView() }
                    NavigationLink("Sync") { SyncSettingsView() }
                }
                Section { Button(role: .destructive) { auth.logout() } label: { Text("auth.logout") } }
            }
            .navigationTitle("tab.settings")
        }
    }
}