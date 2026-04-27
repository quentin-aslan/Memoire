import Foundation
import OSLog
import SwiftData

@Observable
final class ReviewSession: Identifiable {
    let id = UUID()
    var cards: [Card]
    var currentIndex: Int = 0
    var flipped: Bool = false
    var completedRatings: [Rating] = []
    let originalCount: Int
    let startedAt: Date = .now

    private var reviewedCardIDs: Set<UUID> = []
    private var firstPassRatings: [UUID: Rating] = [:]

    private let scheduler = FSRSScheduler()
    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "ReviewSession")

    init(cards: [Card]) {
        self.cards = cards
        self.originalCount = cards.count
    }

    var currentCard: Card? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    var totalCount: Int { cards.count }

    var uniqueReviewedCount: Int { reviewedCardIDs.count }

    // Accuracy = % of cards rated .good/.easy on the first attempt
    var accuracy: Double {
        guard !firstPassRatings.isEmpty else { return 0 }
        let correct = firstPassRatings.values.filter { $0 != .again }.count
        return Double(correct) / Double(firstPassRatings.count)
    }

    var sessionDuration: TimeInterval { Date.now.timeIntervalSince(startedAt) }

    // Progress advances on every rating and never goes backward
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex) / Double(totalCount)
    }

    var isComplete: Bool {
        totalCount == 0 || currentIndex >= totalCount
    }

    func flip() { flipped.toggle() }

    func rate(_ rating: Rating, in context: ModelContext) {
        guard let card = currentCard else { return }
        let now = Date.now

        // Learning steps are an app-layer concern; FSRS is only called on graduation
        // or for cards already in Review/Relearning (learningStep == -1).
        if card.learningStep >= 0 {
            applyLearningStep(to: card, rating: rating, now: now)
        } else {
            scheduler.schedule(card: card, rating: rating, at: now)
        }

        let review = Review(cardID: card.id, rating: rating.rawValue, reviewedAt: now)
        context.insert(review)

        do {
            try context.save()
            if firstPassRatings[card.id] == nil {
                firstPassRatings[card.id] = rating
            }
            if rating == .again {
                cards.append(card)
                // Lifetime cumulative count — drives the permission-to-fail toast
                // (brief §2.4). UI-only state, lives in AppPreferences.
                AppPreferences.shared.cumulativeAgainCount += 1
            } else {
                reviewedCardIDs.insert(card.id)
            }
            completedRatings.append(rating)
            currentIndex += 1
            flipped = false
        } catch {
            context.rollback()
            Self.logger.error("Failed to save review: \(error.localizedDescription)")
        }
    }

    private func applyLearningStep(to card: Card, rating: Rating, now: Date) {
        let steps = AppConstants.LearningSteps.steps
        guard !steps.isEmpty else { return }

        switch rating {
        case .again:
            card.learningStep = 0
            card.nextReviewDate = now.addingTimeInterval(steps[0])
            card.fsrsLastReview = now
            card.fsrsReps += 1

        case .good:
            if card.learningStep < steps.count {
                // Apply the current step's interval, then advance
                card.nextReviewDate = now.addingTimeInterval(steps[card.learningStep])
                card.fsrsLastReview = now
                card.learningStep += 1
                card.fsrsReps += 1
            } else {
                // All steps passed — hand off to FSRS with the card still in .new state
                card.learningStep = -1
                scheduler.schedule(card: card, rating: .good, at: now)
            }

        case .easy:
            if card.learningStep == 0 {
                // First presentation: jump to last step to force at least one overnight
                // before Review — guards against reflex "Easy" on a freshly created card.
                card.learningStep = steps.count
                card.nextReviewDate = now.addingTimeInterval(steps[steps.count - 1])
                card.fsrsLastReview = now
                card.fsrsReps += 1
            } else {
                card.learningStep = -1
                scheduler.schedule(card: card, rating: .easy, at: now)
            }
        }
    }
}
