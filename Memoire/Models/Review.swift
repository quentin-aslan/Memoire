import Foundation
import SwiftData

@Model
final class Review {
    @Attribute(.unique) var id: UUID
    var cardID: UUID
    var rating: Int
    var reviewedAt: Date
    var durationMs: Int?

    var syncVersion: Int
    var syncStatus: Int

    init(
        id: UUID = UUID(),
        cardID: UUID,
        rating: Int,
        reviewedAt: Date = .now,
        durationMs: Int? = nil,
        syncVersion: Int = 0,
        syncStatus: Int = 0
    ) {
        self.id = id
        self.cardID = cardID
        self.rating = rating
        self.reviewedAt = reviewedAt
        self.durationMs = durationMs
        self.syncVersion = syncVersion
        self.syncStatus = syncStatus
    }
}
