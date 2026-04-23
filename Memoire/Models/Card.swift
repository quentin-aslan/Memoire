import Foundation
import SwiftData

@Model
final class Card {
    @Attribute(.unique) var id: UUID
    var front: String
    var back: String
    var createdAt: Date

    var deck: Deck?

    // FSRS state
    var fsrsDifficulty: Double
    var fsrsStability: Double
    var fsrsState: Int
    var fsrsLastReview: Date?
    var fsrsReps: Int
    var fsrsLapses: Int
    var nextReviewDate: Date?

    // Learning steps layer — managed by ReviewSession, not FSRS.
    // 0..N = step index; -1 = graduated (Review/Relearning, FSRS drives scheduling).
    var learningStep: Int

    // Sync preparation
    var isSoftDeleted: Bool
    var deletedAt: Date?
    var syncVersion: Int
    var syncStatus: Int

    init(
        id: UUID = UUID(),
        front: String,
        back: String,
        deck: Deck? = nil,
        createdAt: Date = .now,
        fsrsDifficulty: Double = 5.0,
        fsrsStability: Double = 0.0,
        fsrsState: Int = 0,
        fsrsLastReview: Date? = nil,
        fsrsReps: Int = 0,
        fsrsLapses: Int = 0,
        nextReviewDate: Date? = nil,
        learningStep: Int = 0,
        isSoftDeleted: Bool = false,
        deletedAt: Date? = nil,
        syncVersion: Int = 0,
        syncStatus: Int = 0
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.deck = deck
        self.createdAt = createdAt
        self.fsrsDifficulty = fsrsDifficulty
        self.fsrsStability = fsrsStability
        self.fsrsState = fsrsState
        self.fsrsLastReview = fsrsLastReview
        self.fsrsReps = fsrsReps
        self.fsrsLapses = fsrsLapses
        self.nextReviewDate = nextReviewDate
        self.learningStep = learningStep
        self.isSoftDeleted = isSoftDeleted
        self.deletedAt = deletedAt
        self.syncVersion = syncVersion
        self.syncStatus = syncStatus
    }
}
