import SwiftUI

struct CompleteScreen: View {
    let uniqueCount: Int
    let duration: TimeInterval
    let accuracy: Double
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                goldCheck

                VStack(spacing: 10) {
                    Text("Parfait.")
                        .font(.serif(32, weight: .medium))
                        .foregroundStyle(Color.textReading)

                    Text("Révision terminée.")
                        .font(.serif(17))
                        .italic()
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 32)

                statsRow
                    .padding(.top, 48)

                Spacer()

                Button {
                    onDone()
                } label: {
                    Text("Retour à l'accueil")
                        .font(.uiButton)
                        .foregroundStyle(Color.bgPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.goldLight, .gold],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: .rect(cornerRadius: 14)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    private var goldCheck: some View {
        ZStack {
            Circle()
                .fill(Color.gold.opacity(0.15))
                .frame(width: 104, height: 104)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [.goldLight, .gold, .goldDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .shadow(color: Color.gold.opacity(0.5), radius: 30)

            Image(systemName: "checkmark")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.bgPrimary)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: "\(uniqueCount)", label: "cartes")

            divider

            statCell(value: durationLabel, label: "durée")

            divider

            statCell(value: accuracyLabel, label: "précision", gold: true)
        }
        .padding(.horizontal, 24)
    }

    private func statCell(value: String, label: String, gold: Bool = false) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.serif(28, weight: .medium))
                .foregroundStyle(gold ? Color.gold : Color.textReading)
                .monospacedDigit()

            Text(label.uppercased())
                .font(.sans(11, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(width: 0.5, height: 48)
    }

    private var durationLabel: String {
        let minutes = Int(duration / 60)
        if minutes < 1 { return "< 1 min" }
        return "\(minutes) min"
    }

    private var accuracyLabel: String {
        guard uniqueCount > 0 else { return "—" }
        return "\(Int(accuracy * 100))%"
    }
}

#Preview {
    CompleteScreen(uniqueCount: 12, duration: 384, accuracy: 0.83, onDone: {})
}
