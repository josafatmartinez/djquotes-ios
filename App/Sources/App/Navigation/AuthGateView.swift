import DJQuotesDatabase
import SwiftUI

struct AuthGateView: View {
    @Environment(AuthManager.self) private var auth
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
            if auth.isAuthenticated, let profile = auth.currentProfile {
                MainTabView(profile: profile)
            } else {
                ProfilePickerView()
            }
            }
            .navigationDestination(for: Profile.self) { PinEntryView(profile: $0) }
        }
    }
}

struct MainTabView: View {
    @Environment(AuthManager.self) private var auth
    let profile: Profile
    @State private var tab = AppTab.dashboard

    var body: some View {
        TabView(selection: $tab) {
            DashboardView().tabItem { Label(AppTab.dashboard.label, systemImage: AppTab.dashboard.icon) }.tag(AppTab.dashboard)
            CustomerListView().tabItem { Label(AppTab.customers.label, systemImage: AppTab.customers.icon) }.tag(AppTab.customers)
            QuoteListView().tabItem { Label(AppTab.quotes.label, systemImage: AppTab.quotes.icon) }.tag(AppTab.quotes)
            if profile.role == .admin { CatalogView().tabItem { Label(AppTab.catalog.label, systemImage: AppTab.catalog.icon) }.tag(AppTab.catalog) }
            SettingsView().tabItem { Label(AppTab.settings.label, systemImage: AppTab.settings.icon) }.tag(AppTab.settings)
        }
    }
}

struct DashboardView: View { var body: some View { NavigationStack { ContentUnavailableView("tab.dashboard", systemImage: "rectangle.grid.1x2", description: Text("Coming soon")).navigationTitle("tab.dashboard") } } }
struct CustomerListView: View { var body: some View { NavigationStack { ContentUnavailableView("tab.customers", systemImage: "person.2", description: Text("Coming soon")).navigationTitle("tab.customers") } } }
struct QuoteListView: View { var body: some View { NavigationStack { ContentUnavailableView("tab.quotes", systemImage: "doc.text", description: Text("Coming soon")).navigationTitle("tab.quotes") } } }
struct CatalogView: View { var body: some View { NavigationStack { ContentUnavailableView("tab.catalog", systemImage: "square.grid.2x2", description: Text("Coming soon")).navigationTitle("tab.catalog") } } }

struct SettingsView: View {
    @Environment(AuthManager.self) private var auth
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let p = auth.currentProfile {
                        HStack { Text(p.name); Spacer(); Text(p.role == .admin ? String(localized: "role.admin") : String(localized: "role.seller")).foregroundStyle(.secondary) }
                    }
                    NavigationLink(String(localized: "auth.profiles")) { ProfileListView() }
                }
                Section { Button(role: .destructive) { auth.logout() } label: { Text("auth.logout") } }
            }
            .navigationTitle("tab.settings")
        }
    }
}