import Foundation
import SwiftFSRS

/// Schedules the next review for a card using the FSRS v5 algorithm.
///
/// Wraps `ShortTermScheduler` from the `4rays/swift-fsrs` package, which handles
/// the four learning phases (new / learning / review / relearning) and short
/// intra-session intervals (1 / 5 / 10 min) for the learning phase.
///
/// Usage: `FSRSScheduler().schedule(card: myCard, rating: .good)` — the card is
/// mutated in place with updated FSRS fields and the next due date.
struct FSRSScheduler {
    private let algorithm: FSRSAlgorithm
    private let engine: any SwiftFSRS.Scheduler

    init(retention: Double = AppConstants.FSRS.defaultRetention) {
        var algo = FSRSAlgorithm.v5
        algo.requestRetention = min(max(retention, AppConstants.FSRS.minRetention), AppConstants.FSRS.maxRetention)
        self.algorithm = algo
        self.engine = SchedulerType.shortTerm.implementation
    }

    /// Mutates `card` with the scheduling result for the given rating.
    /// Does NOT insert a Review log — that is the caller's responsibility
    /// (ReviewSession has the ModelContext).
    func schedule(card: Card, rating: Rating, at reviewTime: Date = .now) {
        let snapshot = card.packageSnapshot()
        let result = engine.schedule(
            card: snapshot,
            algorithm: algorithm,
            reviewRating: rating.packageRating(),
            reviewTime: reviewTime
        )
        card.applyFSRS(result.postReviewCard)
    }
}
