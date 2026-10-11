import DJQuotesDatabase
import SwiftUI

struct CreateProfileView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var role: ProfileRole = .admin
    @State private var pin = ""
    @State private var confirmPin = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "auth.profileInfo")) {
                    TextField(String(localized: "auth.name"), text: $name).textContentType(.name)
                    Picker(String(localized: "auth.role"), selection: $role) {
                        Text("role.admin").tag(ProfileRole.admin)
                        Text("role.seller").tag(ProfileRole.seller)
                    }
                }
                Section(String(localized: "auth.security")) {
                    SecureField(String(localized: "auth.pin"), text: $pin).keyboardType(.numberPad)
                        .onChange(of: pin) { _, v in pin = String(v.filter(\.isNumber).prefix(4)) }
                    SecureField(String(localized: "auth.confirmPin"), text: $confirmPin).keyboardType(.numberPad)
                        .onChange(of: confirmPin) { _, v in confirmPin = String(v.filter(\.isNumber).prefix(4)) }
                    if !pin.isEmpty && pin != confirmPin {
                        Text("auth.error.pinMismatch").foregroundStyle(.red).font(.caption)
                    }
                }
                Section { Button(String(localized: "auth.createProfile")) { Task { await submit() } }.disabled(!isValid) }
            }
            .navigationTitle("auth.createProfile").navigationBarTitleDisplayMode(.inline)
        }
    }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && pin.count == 4 && pin == confirmPin }
    private func submit() async { guard await auth.createProfile(name: name, role: role, pin: pin) else { return }; dismiss() }
}