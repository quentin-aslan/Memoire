import Foundation
import SwiftFSRS

// Adapter between our SwiftData @Model Card (reference type) and the SwiftFSRS.Card
// struct (value type). Isolates SwiftData from the FSRS package at the call site.

extension Card {
    /// Builds a value-type FSRS snapshot to pass to the scheduler.
    ///
    /// `elapsedDays` and `scheduledDays` are passed as 0 — ShortTermScheduler
    /// recomputes them from `lastReview` and `reviewTime`, so these input fields
    /// are never read.
    func packageSnapshot() -> SwiftFSRS.Card {
        SwiftFSRS.Card(
            due: nextReviewDate ?? .now,
            stability: fsrsStability,
            difficulty: fsrsDifficulty,
            elapsedDays: 0,
            scheduledDays: 0,
            reps: fsrsReps,
            lapses: fsrsLapses,
            status: Self.status(fromInt: fsrsState),
            lastReview: fsrsLastReview
        )
    }

    /// Writes the post-review FSRS result back onto this @Model.
    func applyFSRS(_ packageCard: SwiftFSRS.Card) {
        fsrsStability = packageCard.stability
        fsrsDifficulty = packageCard.difficulty
        fsrsReps = packageCard.reps
        fsrsLapses = packageCard.lapses
        fsrsLastReview = packageCard.lastReview
        fsrsState = Self.intValue(from: packageCard.status)
        nextReviewDate = packageCard.due
    }

    // MARK: - Status ↔ Int conversion
    // Card.fsrsState stores an Int for SwiftData compatibility; the package uses
    // a String-backed Status enum. FSRSState bridges the two.

    private static func status(fromInt value: Int) -> SwiftFSRS.Status {
        switch FSRSState(rawValue: value) ?? .new {
        case .new:        return .new
        case .learning:   return .learning
        case .review:     return .review
        case .relearning: return .relearning
        }
    }

    private static func intValue(from status: SwiftFSRS.Status) -> Int {
        switch status {
        case .new:        return FSRSState.new.rawValue
        case .learning:   return FSRSState.learning.rawValue
        case .review:     return FSRSState.review.rawValue
        case .relearning: return FSRSState.relearning.rawValue
        }
    }
}

extension Rating {
    func packageRating() -> SwiftFSRS.Rating {
        switch self {
        case .again: return .again
        case .good:  return .good
        case .easy:  return .easy
        }
    }
}
