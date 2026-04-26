import SwiftUI

// State D — pas de deck (premier lancement, ou snapshot stale/absent).
// Trois cartes empilées + invitation serif + flèche discrète.
struct OnboardingView: View {
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                stackedCards
                    .padding(.bottom, 14)

                Text("Créez votre\npremier paquet")
                    .font(.serif(14))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .foregroundStyle(Color.gold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 16)

                arrow
                    .padding(.top, 10)
            }
            .padding(.bottom, 12)

            VStack {
                Spacer()
                WidgetFooter(streakDays: nil)
                    .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var stackedCards: some View {
        ZStack {
            ForEach((0..<3).reversed(), id: \.self) { i in
                let depth = Double(i)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gold.opacity(0.015 + depth * 0.018))
                    .frame(width: 30 + CGFloat(i) * 6, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gold.opacity(0.10 + depth * 0.10), lineWidth: 1)
                    )
                    .offset(x: CGFloat(2 - i) * 3, y: CGFloat(i) * 4)
            }
        }
        .frame(width: 44, height: 32)
    }

    private var arrow: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 11, weight: .light))
            .foregroundStyle(Color.gold.opacity(0.55))
    }
}
