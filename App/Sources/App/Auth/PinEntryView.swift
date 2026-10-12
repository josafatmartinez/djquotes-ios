import DJQuotesDatabase
import SwiftUI
import UIKit

struct PinEntryView: View {
    @Environment(AuthManager.self) private var auth
    let profile: Profile
    @State private var pin = ""
    @State private var shakeAmount: CGFloat = 0
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.tint.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
            }

            VStack(spacing: 8) {
                Text(profile.name)
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            SecureField(String(localized: "auth.pin.placeholder"), text: $pin)
                .keyboardType(.numberPad)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .frame(width: 200)
                .focused($focused)
                .offset(x: shakeAmount)
                .onChange(of: pin) { _, new in
                    let filtered = new.filter(\.isNumber)
                    pin = filtered.count > 4 ? String(filtered.prefix(4)) : filtered
                    if pin.count == 4 { Task { await submit() } }
                }

            if let err = auth.error {
                Text(err)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding()
        .onAppear { focused = true }
    }

    private func submit() async {
        guard await auth.login(pin: pin, profileId: profile.id) else {
            await animateShake()
            pin = ""
            focused = true
            return
        }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func animateShake() async {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        withAnimation(.easeInOut(duration: 0.08).repeatCount(4)) {
            shakeAmount = 8
        }
        shakeAmount = 0
    }
}

import UIKit