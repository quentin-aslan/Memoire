import Foundation
import SwiftData

@Model
final class Deck {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String?
    var position: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card] = []

    var isDeleted: Bool
    var deletedAt: Date?
    var syncVersion: Int
    var syncStatus: Int

    init(
        id: UUID = UUID(),
        name: String,
        color: String? = nil,
        position: Int,
        createdAt: Date = .now,
        isDeleted: Bool = false,
        deletedAt: Date? = nil,
        syncVersion: Int = 0,
        syncStatus: Int = 0
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.position = position
        self.createdAt = createdAt
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.syncVersion = syncVersion
        self.syncStatus = syncStatus
    }
}
