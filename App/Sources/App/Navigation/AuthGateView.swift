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

struct DashboardView: View { var body: some View { NavigationStack { ContentUnavailableView("tab.dashboard", systemImage: "rectangle.grid.1x2", description: Text("Coming soon")).navigationTitle("tab.dashboard") } } }
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