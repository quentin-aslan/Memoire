import Foundation

// Aggregate stability/forecast helpers used by DeckDetailScreen and DeckStatsSheet.
//
// Bands (brief §1.10) — "Solides / En consolidation / À ramener":
//   - Solides:        stability ≥ 21 days AND not overdue
//   - Consolidating:  7 ≤ stability < 21 days AND not overdue
//   - To bring back:  stability < 7 days OR overdue (includes brand-new cards)
//
// Overdue is defined as `nextReviewDate <= now` (≥1 second past due). The
// "≥24h overdue" rule from the status word logic is *not* used here — for
// composition, we want any due-now card to surface in "À ramener" so the user
// sees the actionable count.

extension Deck {
    private var activeCards: [Card] {
        cards.filter { !$0.isSoftDeleted }
    }

    /// Single-pass tally of the three bands. Use this when you need more than
    /// one count — the individual `solidCount` etc. wrappers below trade
    /// brevity at call sites for an extra full pass over the deck.
    var composition: (solid: Int, consolidating: Int, toBack: Int) {
        var s = 0, c = 0, t = 0
        for card in activeCards {
            switch card.stabilityBand {
            case .solid:         s += 1
            case .consolidating: c += 1
            case .toBack:        t += 1
            }
        }
        return (s, c, t)
    }

    var solidCount: Int         { composition.solid }
    var consolidatingCount: Int { composition.consolidating }
    var toBackCount: Int        { composition.toBack }

    var totalActiveCards: Int { activeCards.count }

    /// Number of cards that will become due (or are already due) within the next 7 days.
    func dueThisWeek(now: Date = .now, calendar: Calendar = .current) -> Int {
        let endOfWindow = calendar.date(byAdding: .day, value: 7, to: now) ?? now.addingTimeInterval(7 * 86_400)
        return activeCards.filter { card in
            guard let due = card.nextReviewDate else { return false }
            return due <= endOfWindow
        }.count
    }

    /// Mean stability (in days) over graduated cards. Returns nil for decks
    /// with no graduated cards yet (caller should fall back to "—").
    var meanStability: Double? {
        let graduated = activeCards.filter { $0.fsrsReps > 0 && $0.fsrsStability > 0 }
        guard !graduated.isEmpty else { return nil }
        let sum = graduated.reduce(0.0) { $0 + $1.fsrsStability }
        return sum / Double(graduated.count)
    }

    /// Card counts per day for the next `days` days starting today.
    /// Index 0 = today, index N-1 = today + (N-1) days.
    /// Overdue cards are bucketed into index 0.
    func forecastByDay(_ days: Int = 7, now: Date = .now, calendar: Calendar = .current) -> [Int] {
        var counts = Array(repeating: 0, count: days)
        let startOfToday = calendar.startOfDay(for: now)
        for card in activeCards {
            guard let due = card.nextReviewDate else { continue }
            let startOfDue = calendar.startOfDay(for: due)
            let daysFromToday = calendar.dateComponents([.day], from: startOfToday, to: startOfDue).day ?? 0
            let bucket = max(0, daysFromToday)
            if bucket < days { counts[bucket] += 1 }
        }
        return counts
    }
}

// Per-card stability band — kept on Card so the bucketing logic lives next to
// the data. Not exposed in any UI label; only used to build the composition bar.

enum StabilityBand {
    case solid
    case consolidating
    case toBack
}

extension Card {
    var stabilityBand: StabilityBand {
        let overdue = nextReviewDate.map { $0 <= .now } ?? false
        if overdue { return .toBack }
        if fsrsStability >= AppConstants.FSRS.solidStabilityDays { return .solid }
        if fsrsStability >= AppConstants.FSRS.consolidatingStabilityDays { return .consolidating }
        return .toBack
    }
}
