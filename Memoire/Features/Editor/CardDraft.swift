import Foundation

struct CardDraft: Equatable, Identifiable {
    let id: UUID
    var existingID: UUID?
    var deckID: UUID
    var front: String
    var back: String

    var isEditing: Bool { existingID != nil }

    var trimmedFront: String { front.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedBack: String { back.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isValid: Bool { !trimmedFront.isEmpty && !trimmedBack.isEmpty }

    init(
        existingID: UUID? = nil,
        deckID: UUID,
        front: String = "",
        back: String = ""
    ) {
        self.id = UUID()
        self.existingID = existingID
        self.deckID = deckID
        self.front = front
        self.back = back
    }

    static func edit(_ card: Card) -> CardDraft {
        CardDraft(
            existingID: card.id,
            deckID: card.deck?.id ?? UUID(),
            front: card.front,
            back: card.back
        )
    }
}
