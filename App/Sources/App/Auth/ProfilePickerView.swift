import DJQuotesDatabase
import SwiftUI

struct ProfilePickerView: View {
    @Environment(AuthManager.self) private var auth
    @State private var profiles: [Profile] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "quote.bubble.fill").font(.system(size: 48)).foregroundStyle(.tint)
            Text("app.name", tableName: nil).font(.largeTitle).fontWeight(.bold)
            if isLoading { ProgressView() }
            else if profiles.isEmpty {
                ContentUnavailableView(String(localized: "auth.noProfiles"), systemImage: "person.slash", description: Text("auth.createFirstProfile"))
            } else {
                VStack(spacing: 12) {
                    ForEach(profiles) { profile in
                        NavigationLink(value: profile) {
                            HStack {
                                Image(systemName: profile.isActive ? "person.circle.fill" : "person.circle")
                                    .font(.title2).foregroundStyle(profile.isActive ? .primary : .secondary)
                                VStack(alignment: .leading) {
                                    Text(profile.name).font(.headline)
                                    Text(profile.role.displayName).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if !profile.isActive { Text("auth.accountDisabled").font(.caption2).foregroundStyle(.red) }
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                            }
                            .padding().background(.regularMaterial).clipShape(.rect(cornerRadius: 12))
                        }
                        .buttonStyle(.plain).disabled(!profile.isActive)
                    }
                }.padding(.horizontal)
            }
            Spacer()
        }
        .task { do { profiles = try await auth.fetchProfiles() } catch { profiles = [] }; isLoading = false }
    }
}