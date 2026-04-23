import Foundation
import OSLog
import SwiftData

/// One-shot idempotent migration for cards created before the real FSRS integration.
///
/// Before that integration, a placeholder scheduler left `fsrsState` inconsistent.
/// This migration ensures every card has a coherent state:
/// - Never reviewed (`fsrsReps == 0 && fsrsLastReview == nil`) → `.new`
/// - Already reviewed → `.review`
///
/// Existing `nextReviewDate` values are never modified — user-built schedules
/// are always respected.
///
/// Gated by a UserDefaults version key so it only runs once per install.
enum SchedulerMigration {
    private static let versionKey = "schedulerMigrationVersion"
    private static let currentVersion = 2
    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "SchedulerMigration")

    static func runIfNeeded(in context: ModelContext) {
        let stored = UserDefaults.standard.integer(forKey: versionKey)
        guard stored < currentVersion else { return }

        do {
            let descriptor = FetchDescriptor<Card>(predicate: #Predicate { !$0.isSoftDeleted })
            let cards = try context.fetch(descriptor)

            for card in cards {
                let isPristine = card.fsrsReps == 0 && card.fsrsLastReview == nil
                let expected = isPristine ? FSRSState.new.rawValue : FSRSState.review.rawValue
                if card.fsrsState != expected {
                    card.fsrsState = expected
                }
                // Cards already reviewed before learning steps existed are graduated.
                // New cards (fsrsReps == 0) keep learningStep = 0 (default) to enter steps.
                if card.fsrsReps > 0 {
                    card.learningStep = -1
                }
            }

            try context.save()
            UserDefaults.standard.set(currentVersion, forKey: versionKey)
            logger.info("Scheduler migration v\(currentVersion) completed on \(cards.count) cards.")
        } catch {
            logger.error("Scheduler migration failed: \(error.localizedDescription)")
        }
    }
}
