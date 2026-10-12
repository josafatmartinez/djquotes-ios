import DJQuotesDatabase
import SwiftUI

struct ProfilePickerView: View {
    @Environment(AuthManager.self) private var auth
    @State private var profiles: [Profile] = []
    @State private var isLoading = true
    @State private var showCreateFirst = false
    @State private var selectedProfileForPin: Profile?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.tint.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.tint)
            }

            Text("app.name").font(.largeTitle).fontWeight(.bold)
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
                        Button {
                            selectedProfileForPin = profile
                        } label: {
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
        .sheet(item: $selectedProfileForPin) { profile in
            PinEntryView(profile: profile)
        }
    }
}

struct OnboardingCreateProfileView: View {
    @Environment(AuthManager.self) private var auth
    let onCreated: (Profile) -> Void

    @State private var name = ""
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var isCreating = false
    @FocusState private var focusedField: Field?

    enum Field { case name, pin, confirmPin }

    private var pinMatch: Bool { pin.count == 4 && confirmPin.count == 4 && pin == confirmPin }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    formSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("app.name")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.tint)
            }

            VStack(spacing: 8) {
                Text("auth.createFirstProfile")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("auth.createFirstProfileDescription")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var formSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    TextField(String(localized: "auth.name"), text: $name)
                        .textContentType(.name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .pin }
                }
                .padding(12)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    SecureField(String(localized: "auth.pin.placeholder"), text: $pin)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .pin)
                        .onChange(of: pin) { _, v in
                            pin = String(v.filter(\.isNumber).prefix(4))
                            if pin.count == 4 { focusedField = .confirmPin }
                        }
                    if pinMatch {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.callout)
                    }
                }
                .padding(12)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                HStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    SecureField(String(localized: "auth.confirmPin"), text: $confirmPin)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .confirmPin)
                        .onChange(of: confirmPin) { _, v in
                            confirmPin = String(v.filter(\.isNumber).prefix(4))
                        }
                    if pinMatch {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.callout)
                    }
                }
                .padding(12)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                if let err = auth.error {
                    Text(err)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !pin.isEmpty && !pinMatch {
                    Text("auth.error.pinMismatch")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Button {
                isCreating = true
                Task { await create() }
            } label: {
                Group {
                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("auth.createProfile")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!isValid || isCreating)
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && pin.count == 4
            && confirmPin.count == 4
            && pin == confirmPin
    }

    private func create() async {
        guard await auth.createProfile(name: name, role: .admin, pin: pin) else {
            isCreating = false
            return
        }
        do {
            let profiles = try await auth.fetchProfiles()
            if let created = profiles.first(where: { $0.name == name.trimmingCharacters(in: .whitespaces) }) {
                onCreated(created)
            }
        } catch {
            isCreating = false
        }
    }
}