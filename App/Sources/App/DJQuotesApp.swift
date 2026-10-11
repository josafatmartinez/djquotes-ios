import SwiftUI
import DJQuotesDatabase

@main
struct DJQuotesApp: App {
    @State private var auth = AuthManager()
    @State private var dbReady = false

    var body: some Scene {
        WindowGroup {
            Group {
            if dbReady {
                AuthGateView().environment(auth)
            } else {
                ProgressView("app.loading")
            }
            }
            .task {
            do { try DatabaseManager.shared.initialize() } catch {}
            dbReady = true
            }
        }
    }
}