import SwiftUI

// One-shot toast shown the first time the user has accumulated 3 "À revoir"
// ratings across all sessions. Reframes "À revoir" from failure to information.
// Brief §2.4 — Liquid Glass top + 12pt safe area, auto-dismiss 4s.
//
// Trigger logic lives in ReviewScreen (reads AppPreferences.cumulativeAgainCount
// + permissionToFailToastShown after each rating). This view owns its own
// dismissal timer once shown.

struct ReviewToast: View {
    @Binding var visible: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if visible {
            HStack {
                Text(message)
                    .font(.sans(15))
                    .foregroundStyle(Color.textReading)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .memoireSurface(in: .rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.textReading.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
            .padding(.horizontal, 16)
            .transition(transition)
            .task { await scheduleDismiss() }
            .onTapGesture { dismiss() }
        }
    }

    private var message: String {
        // Variante factuelle si l'utilisateur a réduit les animations — heuristique
        // de respect de l'aversion potentielle aux microcopies sentimentales.
        reduceMotion
            ? "À revoir signale à Mémoire de revenir bientôt."
            : "À revoir, ce n'est pas un échec — c'est de l'information."
    }

    private var transition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity.combined(with: .offset(y: -8))
        )
    }

    private func scheduleDismiss() async {
        try? await Task.sleep(for: .seconds(4))
        dismiss()
    }

    private func dismiss() {
        if reduceMotion {
            visible = false
        } else {
            withAnimation(.easeIn(duration: 0.24)) { visible = false }
        }
    }
}
