import DJQuotesDatabase
import SwiftUI

struct ProfilePickerView: View {
    @Environment(AuthManager.self) private var auth
    @State private var profiles: [Profile] = []
    @State private var isLoading = true
    @State private var showCreateFirst = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "quote.bubble.fill").font(.system(size: 48)).foregroundStyle(.tint)
            Text("app.name", tableName: nil).font(.largeTitle).fontWeight(.bold)
            if isLoading { ProgressView() }
            else if profiles.isEmpty {
                VStack(spacing: 16) {
                    ContentUnavailableView(
                        String(localized: "auth.noProfiles"),
                        systemImage: "person.slash",
                        description: Text("auth.createFirstProfile")
                    )
                    Button {
                        showCreateFirst = true
                    } label: {
                        Label(String(localized: "auth.createProfile"), systemImage: "person.badge.plus")
                            .frame(maxWidth: 280)
                    }
                    .buttonStyle(.borderedProminent)
                }
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
        .task {
            do { profiles = try await auth.fetchProfiles() } catch { profiles = [] }
            isLoading = false
            if profiles.isEmpty { showCreateFirst = true }
        }
        .fullScreenCover(isPresented: $showCreateFirst) {
            OnboardingCreateProfileView { profile in
                auth.switchProfile(to: profile)
                showCreateFirst = false
            }
        }
    }
}

struct OnboardingCreateProfileView: View {
    @Environment(AuthManager.self) private var auth
    let onCreated: (Profile) -> Void

    @State private var name = ""
    @State private var pin = ""
    @State private var confirmPin = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("auth.createFirstProfile")
                .font(.title2)
                .fontWeight(.bold)

            Text("auth.createFirstProfileDescription")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                TextField(String(localized: "auth.name"), text: $name)
                    .textContentType(.name)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 280)

                SecureField(String(localized: "auth.pin.placeholder"), text: $pin)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 280)
                    .onChange(of: pin) { _, v in
                        pin = String(v.filter(\.isNumber).prefix(4))
                    }

                SecureField(String(localized: "auth.confirmPin"), text: $confirmPin)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 280)
                    .onChange(of: confirmPin) { _, v in
                        confirmPin = String(v.filter(\.isNumber).prefix(4))
                    }

                if let err = auth.error {
                    Text(err).font(.callout).foregroundStyle(.red)
                }

                if !pin.isEmpty && pin != confirmPin {
                    Text("auth.error.pinMismatch")
                        .font(.caption).foregroundStyle(.red)
                }
            }

            Button {
                Task { await create() }
            } label: {
                Text("auth.createProfile")
                    .frame(maxWidth: 280)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)

            Spacer()
        }
        .padding()
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && pin.count == 4
            && pin == confirmPin
    }

    private func create() async {
        guard await auth.createProfile(name: name, role: .admin, pin: pin) else { return }
        do {
            let profiles = try await auth.fetchProfiles()
            if let created = profiles.first(where: { $0.name == name.trimmingCharacters(in: .whitespaces) }) {
                onCreated(created)
            }
        } catch {}
    }
}