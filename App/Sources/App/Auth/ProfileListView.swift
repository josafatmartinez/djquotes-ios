import DJQuotesDatabase
import SwiftUI

struct ProfileListView: View {
    @Environment(AuthManager.self) private var auth
    @State private var profiles: [Profile] = []
    @State private var showCreate = false

    var body: some View {
        List {
            ForEach(profiles) { profile in
                HStack {
                    VStack(alignment: .leading) {
                        Text(profile.name).font(.headline)
                        Text(profile.role.displayName).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !profile.isActive { Text("Inactive").font(.caption2).foregroundStyle(.red) }
                    Toggle("", isOn: Binding(get: { profile.isActive }, set: { v in Task { await auth.toggleProfileActive(profile, isActive: v) } })).labelsHidden()
                }
            }
        }
        .navigationTitle("auth.profiles")
        .toolbar { ToolbarItem(placement: .primaryAction) { Button { showCreate = true } label: { Image(systemName: "plus") } } }
        .sheet(isPresented: $showCreate) { CreateProfileView() }
        .task { profiles = (try? await auth.fetchProfiles()) ?? [] }
    }
}