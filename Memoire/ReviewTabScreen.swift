import SwiftData
import SwiftUI

struct ReviewTabScreen: View {
    @Environment(\.appPreferences) private var prefs
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

    private var regularity: Int {
        RegularityCalculator.compute(reviews: allReviews)
    }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            if dueCards.isEmpty {
                EmptyDueState(regularityDays: regularity)
            } else {
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 8) {
                        Text("\(dueCards.count)")
                            .font(.serif(72, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                            .contentTransition(.numericText(value: Double(dueCards.count)))

                        Text("CARTES À RÉVISER")
                            .font(.sans(13))
                            .tracking(1.2)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Button {
                        activeSession = ReviewSession(cards: dueCards)
                    } label: {
                        Text("Commencer la révision (\(dueCards.count) carte\(dueCards.count == 1 ? "" : "s"))")
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
        .animation(.easeInOut(duration: 0.3), value: dueCards.isEmpty)
        .fullScreenCover(item: $activeSession) { session in
            ReviewScreen(session: session)
        }
    }
}

#Preview {
    ReviewTabScreen()
        .modelContainer(for: [Deck.self, Card.self, Review.self], inMemory: true)
}
