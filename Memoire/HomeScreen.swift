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
    private var regularityStreak: Int { RegularityCalculator.currentStreak(reviews: allReviews) }
    private let regularityMax: Int = AppConstants.Regularity.windowDays

    private var nextDueDate: Date? {
        DailyQueue.nextDueDate(allCards: allCards)
    }

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
                    EmptyDueState(
                        regularityDays: regularity,
                        nextDueDate: nextDueDate
                    )
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

            Text(greetingLine)
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
                    .contentTransition(prefs.calmMode ? .identity : .numericText(value: Double(cardsDue)))

                Text(cardsDue == 1 ? "CARTE À RÉVISER" : "CARTES À RÉVISER")
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

                Text(regularitySubtitle)
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
                guard !dueCards.isEmpty else { return }
                activeSession = ReviewSession(cards: dueCards)
            } label: {
                Text(ctaLabel)
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

            Text(ctaSubtitle)
                .font(.sans(13))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    private var greetingLine: String {
        let base = greetingForHour(Calendar.current.component(.hour, from: .now))
        if let name = AppPreferences.sanitize(prefs.firstName) {
            return "\(base), \(name)."
        }
        return base
    }

    private func greetingForHour(_ hour: Int) -> String {
        switch hour {
        case 5...11:  return "Bonjour"
        case 12...17: return "Bon après-midi"
        case 18...23: return "Bonsoir"
        default:      return "Bonne nuit"
        }
    }

    private var ctaLabel: String {
        switch cardsDue {
        case 1:     return "Avancer d'une carte"
        case 2...5: return "Avancer de \(cardsDue) cartes"
        default:    return "Avancer"
        }
    }

    private var ctaSubtitle: String {
        // TDAH: 0-4 h → on retire l'urgence. L'hyperfocus nocturne se retourne
        // vite contre l'utilisateur, la session peut attendre le matin.
        let hour = Calendar.current.component(.hour, from: .now)
        if (0...4).contains(hour) {
            return "À faire quand vous voulez."
        }
        return "\(timeEstimate(for: cardsDue)) · \(cardsDue) \(cardsDue == 1 ? "carte" : "cartes")"
    }

    private func timeEstimate(for count: Int) -> String {
        // TDAH: cap anti-ancrage. Au-delà de 100 cartes, dire "20 min ou plus"
        // évite d'afficher un chiffre effrayant qui déclenche l'évitement.
        if count > 100 { return "≈ 20 minutes ou plus" }

        let seconds = Double(count) * AppConstants.FSRS.avgSecondsPerCard
        if seconds < 60 { return "≈ 1 minute" }

        if seconds <= 600 {
            let minutes = max(1, Int((seconds / 60).rounded()))
            return "≈ \(minutes) \(minutes == 1 ? "minute" : "minutes")"
        }

        let fiveMinChunks = max(1, Int((seconds / 300).rounded()))
        return "≈ \(fiveMinChunks * 5) minutes"
    }

    private var regularitySubtitle: String {
        switch regularityStreak {
        case 0:  return "30 derniers jours"
        case 1:  return "1 jour d'affilée · 30 derniers jours"
        default: return "\(regularityStreak) jours d'affilée · 30 derniers jours"
        }
    }
}

#Preview {
    HomeScreen()
        .modelContainer(for: [Deck.self, Card.self, Review.self], inMemory: true)
}
