import SwiftData
import SwiftUI

struct HomeScreen: View {
    @Environment(\.appPreferences) private var prefs
    @Environment(\.deckCreation) private var deckCreation
    @Query private var allCards: [Card]
    @Query private var allReviews: [Review]
    @State private var activeSession: ReviewSession?

    private var dueCards: [Card] {
        DailyQueue.build(
            allCards: allCards,
            allReviews: allReviews,
            dailyNewCards: prefs.dailyNewCards
        )
    }

    private var cardsDue: Int { dueCards.count }

    private var totalCards: Int {
        allCards.filter { !$0.isSoftDeleted }.count
    }

    private var completionProgress: Double {
        guard totalCards > 0 else { return 0 }
        return Double(totalCards - cardsDue) / Double(totalCards)
    }

    private var regularity: Int { RegularityCalculator.compute(reviews: allReviews) }
    private let regularityMax: Int = AppConstants.Regularity.windowDays

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE d MMMM"
        return f
    }()

    private var dateHeader: String {
        Self.dateFormatter.string(from: .now).uppercased()
    }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if totalCards == 0 {
                    Spacer()
                    EmptyDecksState(
                        onCreateDeck: { deckCreation.open() }
                    )
                    Spacer()
                } else if cardsDue == 0 {
                    EmptyDueState(regularityDays: regularity)
                    regularityCard
                    Spacer()
                } else {
                    ringHero
                    regularityCard
                    Spacer()
                    cta
                }
            }
        }
        .fullScreenCover(item: $activeSession) { session in
            ReviewScreen(session: session)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(dateHeader)
                .font(.sans(13, weight: .medium))
                .tracking(1.6)
                .foregroundStyle(Color.textSecondary)

            Text("Bonsoir, Quentin.")
                .font(.serif(34, weight: .medium))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private var ringHero: some View {
        ZStack {
            ProgressRing(progress: completionProgress)

            VStack(spacing: 8) {
                Text("\(cardsDue)")
                    .font(.serif(72, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                    .contentTransition(.numericText(value: Double(cardsDue)))

                Text("CARTES À RÉVISER")
                    .font(.sans(13))
                    .tracking(1.2)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.top, 38)
    }

    private var regularityCard: some View {
        HStack(spacing: 14) {
            ProgressRing(
                progress: Double(regularity) / Double(regularityMax),
                size: 36,
                lineWidth: 4
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Score de régularité")
                    .font(.sans(16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Text("Sur les 30 derniers jours")
                    .font(.sans(13))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("\(regularity)")
                    .font(.serif(26, weight: .medium))
                    .foregroundStyle(Color.gold)
                Text("/\(regularityMax)")
                    .font(.serif(18, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(18)
        .background(Color.bgCard, in: .rect(cornerRadius: 18))
        .padding(.horizontal, 20)
        .padding(.top, 38)
    }

    private var cta: some View {
        VStack(spacing: 12) {
            Button {
                activeSession = ReviewSession(cards: dueCards)
            } label: {
                Text(cardsDue > 0 ? "Commencer la révision" : "Avancer quelques cartes")
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
            .disabled(dueCards.isEmpty)

            Text(cardsDue > 0 ? "≈ 5 minutes · \(cardsDue) cartes" : "Vous pouvez vous arrêter ici.")
                .font(.sans(13))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
}

#Preview {
    HomeScreen()
        .modelContainer(for: [Deck.self, Card.self, Review.self], inMemory: true)
}
