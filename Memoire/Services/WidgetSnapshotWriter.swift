import Foundation
import OSLog
import SwiftData
import WidgetKit

// Computes a WidgetSnapshot from SwiftData and persists it to the App Group
// container, then asks WidgetKit to reload all timelines. Centralised here so
// every reload trigger goes through a single, instrumented choke point.
enum WidgetSnapshotWriter {
    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "WidgetSnapshotWriter")

    @MainActor
    static func refresh(context: ModelContext, prefs: AppPreferences) {
        let snapshot = build(context: context, prefs: prefs)
        do {
            try WidgetSnapshot.write(snapshot)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            logger.error("Snapshot write failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    private static func build(context: ModelContext, prefs: AppPreferences) -> WidgetSnapshot {
        let now = Date.now
        let calendar = Calendar.current

        // Push the soft-delete filter into the descriptor so we don't drag dead
        // rows into memory at scale. CLAUDE.md bans silent `try?` swallow.
        let activeCardsDescriptor = FetchDescriptor<Card>(
            predicate: #Predicate { !$0.isSoftDeleted }
        )
        let activeDecksDescriptor = FetchDescriptor<Deck>(
            predicate: #Predicate { !$0.isSoftDeleted }
        )

        let activeCards: [Card]
        let activeDecks: [Deck]
        let reviews: [Review]
        do {
            activeCards = try context.fetch(activeCardsDescriptor)
            activeDecks = try context.fetch(activeDecksDescriptor)
            reviews = try context.fetch(FetchDescriptor<Review>())
        } catch {
            logger.error("Snapshot fetch failed: \(error.localizedDescription)")
            return WidgetSnapshot(
                hasAnyDeck: false, dueNow: 0, reviewedToday: 0, totalToday: 0,
                nextDueDate: nil, laterTodayCount: 0, streakDays: 0,
                generatedAt: now, schemaVersion: WidgetSnapshot.currentSchemaVersion
            )
        }

        // Same predicate as DailyQueue.build → widget and Home never disagree
        let dueNonNew = activeCards.filter { card in
            guard card.fsrsReps > 0, let next = card.nextReviewDate else { return false }
            return next <= now
        }

        let introduced = DailyQueue.newCardsIntroducedToday(reviews: reviews, now: now, calendar: calendar)
        let remainingNew = max(0, prefs.dailyNewCards - introduced)
        let newQueueCount = min(remainingNew, activeCards.filter { $0.fsrsReps == 0 }.count)
        let dueNow = dueNonNew.count + newQueueCount

        let reviewedToday: Int = {
            let startOfDay = calendar.startOfDay(for: now)
            return Set(reviews.filter { $0.reviewedAt >= startOfDay }.map(\.cardID)).count
        }()

        let nextDueDate = DailyQueue.nextDueDate(allCards: activeCards, now: now)

        let endOfToday: Date = {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86_400)
            return calendar.startOfDay(for: tomorrow)
        }()
        let laterTodayCount = activeCards.filter { card in
            guard card.fsrsReps > 0, let next = card.nextReviewDate else { return false }
            return next > now && next < endOfToday
        }.count

        let streakDays = RegularityCalculator.currentStreak(reviews: reviews, referenceDate: now)

        return WidgetSnapshot(
            hasAnyDeck: !activeDecks.isEmpty,
            dueNow: dueNow,
            reviewedToday: reviewedToday,
            totalToday: dueNow + reviewedToday,
            nextDueDate: nextDueDate,
            laterTodayCount: laterTodayCount,
            streakDays: streakDays,
            generatedAt: now,
            schemaVersion: WidgetSnapshot.currentSchemaVersion
        )
    }
}
