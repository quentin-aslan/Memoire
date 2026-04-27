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
        let active = allCards.filter { !$0.isSoftDeleted }

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
            guard !card.isSoftDeleted,
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

    static func nextDueDate(
        allCards: [Card],
        now: Date = .now
    ) -> Date? {
        allCards
            .lazy
            .filter { !$0.isSoftDeleted }
            .compactMap(\.nextReviewDate)
            .filter { $0 > now }
            .min()
    }

    /// Returns (date, cardCount) for each future day where review cards are due,
    /// up to `days` days ahead. New cards (fsrsReps == 0) are excluded — their
    /// introduction day is unpredictable without session context.
    static func futureDueDates(
        allCards: [Card],
        days: Int = 30,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [(date: Date, count: Int)] {
        guard let horizon = calendar.date(byAdding: .day, value: days, to: now) else { return [] }

        var grouped: [Date: Int] = [:]
        for card in allCards {
            guard !card.isSoftDeleted,
                  card.fsrsReps > 0,
                  let next = card.nextReviewDate,
                  next > now,
                  next <= horizon else { continue }
            let day = calendar.startOfDay(for: next)
            grouped[day, default: 0] += 1
        }
        return grouped
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value) }
    }
}
