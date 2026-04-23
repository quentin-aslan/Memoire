import SwiftUI

struct EmptyDecksState: View {
    let onCreateDeck: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            monogram

            Text("Commencez par un\npremier paquet.")
                .font(.serif(24, weight: .medium))
                .foregroundStyle(Color.textReading)
                .multilineTextAlignment(.center)
                .padding(.top, 28)

            Text("Organisez vos cartes par sujet. Ajoutez des questions, laissez l'algorithme faire le reste.")
                .font(.sans(15))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 280)
                .padding(.top, 12)

            VStack(spacing: 12) {
                Button("+ Créer un paquet", action: onCreateDeck)
                    .buttonStyle(.primary)
                    .accessibilityLabel("Créer un paquet")
            }
            .padding(.top, 36)
        }
        .padding(.horizontal, 28)
        .padding(.top, 48)
    }

    private var monogram: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [.goldLight, .goldDark],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 4,
                        endRadius: 90
                    )
                )
                .shadow(color: Color.gold.opacity(0.25), radius: 40, y: 10)
                .frame(width: 88, height: 88)

            Text("M")
                .font(.serif(44, weight: .medium))
                .foregroundStyle(Color.onGold)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mémoire")
    }
}

#Preview {
    ZStack {
        Color.bgPrimary.ignoresSafeArea()
        EmptyDecksState(onCreateDeck: {})
    }
}
