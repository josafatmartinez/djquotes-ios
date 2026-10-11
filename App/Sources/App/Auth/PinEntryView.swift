import DJQuotesDatabase
import SwiftUI

struct PinEntryView: View {
    @Environment(AuthManager.self) private var auth
    let profile: Profile
    @State private var pin = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "person.circle.fill").font(.system(size: 64)).foregroundStyle(.secondary)
            Text(profile.name).font(.title2).fontWeight(.semibold)
            Text(profile.role.displayName).font(.subheadline).foregroundStyle(.secondary)
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(profile.role.color.opacity(0.15)).clipShape(.capsule)
            SecureField(String(localized: "auth.pin.placeholder"), text: $pin)
                .keyboardType(.numberPad).font(.largeTitle).multilineTextAlignment(.center)
                .frame(width: 200).focused($focused)
                .onChange(of: pin) { _, new in
                    let filtered = new.filter(\.isNumber)
                    pin = filtered.count > 4 ? String(filtered.prefix(4)) : filtered
                    if pin.count == 4 { Task { await submit() } }
                }
            if let err = auth.error { Text(err).font(.callout).foregroundStyle(.red) }
            Spacer()
        }
        .padding().onAppear { focused = true }
    }

    private func submit() async {
        guard await auth.login(pin: pin, profileId: profile.id) else {
            pin = ""; focused = true; return
        }
    }
}

extension ProfileRole {
    var displayName: String {
        switch self {
        case .admin: String(localized: "role.admin")
        case .seller: String(localized: "role.seller")
        }
    }
    var color: Color {
        switch self {
        case .admin: .purple
        case .seller: .blue
        }
    }
}