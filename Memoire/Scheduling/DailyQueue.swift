import Foundation

// Due non-new cards have no cap; new cards are limited by dailyNewCards
// to prevent overwhelming the learner on any given day.
enum DailyQueue {
    static func build(
        allCards: [Card],
        allReviews: [Review],
        dailyNewCards: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Card] {
        let active = allCards.filter { !$0.isDeleted }

        let dueNonNew = active.filter { card in
            guard card.fsrsReps > 0, let next = card.nextReviewDate else { return false }
            return next <= now
        }

        let introduced = newCardsIntroducedToday(reviews: allReviews, now: now, calendar: calendar)
        let remaining = max(0, dailyNewCards - introduced)

        let newCards = Array(
            active
                .filter { $0.fsrsReps == 0 }
                .sorted { $0.createdAt < $1.createdAt }
                .prefix(remaining)
        )

        return dueNonNew + newCards
    }

    /// Returns true if any active card has a nextReviewDate within today but not yet due.
    /// Used to distinguish "done for now, come back later" from "done for the day".
    static func hasCardsDueToday(
        allCards: [Card],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
        let endOfDay = calendar.startOfDay(for: tomorrow)
        return allCards.contains { card in
            guard !card.isDeleted,
                  card.fsrsReps > 0,
                  let next = card.nextReviewDate else { return false }
            return next > now && next < endOfDay
        }
    }

    static func newCardsIntroducedToday(
        reviews: [Review],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let startOfDay = calendar.startOfDay(for: now)
        let todaysIDs = Set(reviews.filter { $0.reviewedAt >= startOfDay }.map(\.cardID))
        guard !todaysIDs.isEmpty else { return 0 }
        let priorIDs = Set(reviews.filter { $0.reviewedAt < startOfDay }.map(\.cardID))
        return todaysIDs.subtracting(priorIDs).count
    }
}
