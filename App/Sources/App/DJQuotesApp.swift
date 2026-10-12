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
                    splashView
                }
            }
            .task {
                do { try DatabaseManager.shared.initialize() } catch {}
                dbReady = true
            }
        }
    }

    private var splashView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.tint)
            }
            Text("app.name")
                .font(.title)
                .fontWeight(.bold)
            ProgressView()
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}