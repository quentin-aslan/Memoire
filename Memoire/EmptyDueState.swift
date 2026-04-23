import SwiftUI

struct EmptyDueState: View {
    let regularityDays: Int
    var hasPendingToday: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            checkCircle

            Text("Journée terminée.")
                .font(.serif(32, weight: .medium))
                .foregroundStyle(Color.textReading)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 28)

            Text(hasPendingToday
                 ? "Revenez plus tard.\nPour le moment toutes vos cartes sont validées."
                 : "Toutes vos cartes sont à jour.\nRevenez demain pour poursuivre.")
                .font(.serif(17).italic())
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 10)
                .padding(.horizontal, 24)

            Text("Votre cerveau consolide maintenant.\nLa pause fait partie de l'apprentissage.")
                .font(.sans(13))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 8)
                .padding(.horizontal, 32)

            regularityPill
                .padding(.top, 24)
        }
        .padding(.top, 56)
    }

    private var checkCircle: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.goldLight, .gold, .goldDark],
                        startPoint: UnitPoint(x: 0.2, y: 0.1),
                        endPoint: UnitPoint(x: 0.8, y: 0.9)
                    )
                )
                .shadow(color: Color.gold.opacity(0.4), radius: 20)
                .shadow(color: Color.black.opacity(0.3), radius: 10, y: 10)
                .frame(width: 72, height: 72)

            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.onGold)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Révision complète")
    }

    private var regularityPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 10, weight: .bold))
                .accessibilityHidden(true)
            Text("\(regularityDays) jour\(regularityDays == 1 ? "" : "s") de régularité")
                .font(.sans(12, weight: .semibold))
                .tracking(1.2)
        }
        .foregroundStyle(Color.gold)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.goldTint, in: .capsule)
    }
}

#Preview {
    ZStack {
        Color.bgPrimary.ignoresSafeArea()
        EmptyDueState(regularityDays: 7)
    }
}
