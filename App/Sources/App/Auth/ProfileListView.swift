import DJQuotesDatabase
import SwiftUI

struct ProfileListView: View {
    @Environment(AuthManager.self) private var auth
    @State private var profiles: [Profile] = []
    @State private var showCreate = false

    var body: some View {
        List {
            ForEach(profiles) { profile in
                let isCurrent = profile.id == auth.currentProfile?.id
                HStack {
                    VStack(alignment: .leading) {
                        Text(profile.name).font(.headline)
                        HStack(spacing: 6) {
                            Text(profile.role.displayName).font(.caption).foregroundStyle(.secondary)
                            if isCurrent {
                                Text("—").font(.caption2).foregroundStyle(.tertiary)
                                Text("auth.profiles.current")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    Spacer()
                    if !profile.isActive { Text("Inactive").font(.caption2).foregroundStyle(.red) }
                    Toggle("", isOn: Binding(
                        get: { profile.isActive },
                        set: { v in Task { await auth.toggleProfileActive(profile, isActive: v) } }
                    ))
                    .labelsHidden()
                    .disabled(isCurrent)
                }
            }
        }
        .navigationTitle("auth.profiles")
        .toolbar { ToolbarItem(placement: .primaryAction) { Button { showCreate = true } label: { Image(systemName: "plus") } } }
        .sheet(isPresented: $showCreate) { CreateProfileView() }
        .task { profiles = (try? await auth.fetchProfiles()) ?? [] }
    }
}