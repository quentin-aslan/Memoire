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

        // The card mutation (scheduler) and the Review insert are committed in the
        // same save(). If save() fails, we rollback the context (discarding in-memory
        // mutations) and do NOT advance the session — the user sees the same card again.
        scheduler.schedule(card: card, rating: rating, at: now)
        let review = Review(cardID: card.id, rating: rating.rawValue, reviewedAt: now)
        context.insert(review)

        do {
            try context.save()
            if firstPassRatings[card.id] == nil {
                firstPassRatings[card.id] = rating
            }
            if rating == .again {
                cards.append(card)
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
}
