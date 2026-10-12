import GRDB
import Foundation
import CryptoKit
import LocalAuthentication
import UIKit
import DJQuotesDatabase

@MainActor
@Observable
final class AuthManager {
    private(set) var currentProfile: Profile?
    private(set) var isAuthenticated = false
    private(set) var error: String?

    func login(pin: String, profileId: String) async -> Bool {
        guard pin.count == 4, pin.allSatisfy(\.isNumber) else {
            error = String(localized: "auth.error.invalidPin")
            return false
        }
        do {
            let profile: Profile? = try await DatabaseManager.shared.read { db in
                try Profile.filter(Column("id") == profileId).fetchOne(db)
            }
            guard let profile, profile.isActive else {
                error = profile == nil
                    ? String(localized: "auth.error.profileNotFound")
                    : String(localized: "auth.error.accountDisabled")
                return false
            }
            guard hashPin(pin) == profile.pinHash else {
                error = String(localized: "auth.error.wrongPin")
                return false
            }
            currentProfile = profile
            isAuthenticated = true
            error = nil
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return false }
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: String(localized: "auth.biometrics.reason"))
            if success { isAuthenticated = true }
            return success
        } catch { return false }
    }

    func createProfile(name: String, pin: String) async -> Bool {
        guard pin.count == 4, pin.allSatisfy(\.isNumber) else {
            error = String(localized: "auth.error.invalidPin")
            return false
        }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = String(localized: "auth.error.emptyName")
            return false
        }
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let profile = Profile(id: UUID().uuidString, name: name.trimmingCharacters(in: .whitespaces), pinHash: hashPin(pin), isActive: true, deviceId: deviceId, deviceName: UIDevice.current.name, createdAt: Date())
        do {
            try await DatabaseManager.shared.write { db in try profile.insert(db) }
            error = nil
            return true
        } catch {
            self.error = String(localized: "auth.error.createFailed")
            return false
        }
    }

    func switchProfile(to profile: Profile) {
        currentProfile = profile
        isAuthenticated = true
    }

    func toggleProfileActive(_ profile: Profile, isActive: Bool) async -> Bool {
        do {
            try await DatabaseManager.shared.write { db in
                var p = profile; p.isActive = isActive; try p.update(db)
            }
            if currentProfile?.id == profile.id {
                currentProfile?.isActive = isActive
                if !isActive { logout() }
            }
            return true
        } catch { self.error = error.localizedDescription; return false }
    }

    func logout() {
        currentProfile = nil
        isAuthenticated = false
        error = nil
    }

    func fetchProfiles() async throws -> [Profile] {
        try await DatabaseManager.shared.read { db in try Profile.order(Column("name").asc).fetchAll(db) }
    }

    private func hashPin(_ pin: String) -> String {
        SHA256.hash(data: Data(pin.utf8)).compactMap { String(format: "%02x", $0) }.joined()
    }
}