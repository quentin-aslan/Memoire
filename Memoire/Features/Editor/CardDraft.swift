import Foundation

enum BackMode: Equatable {
    case text
    case drawing
}

struct CardDraft: Equatable, Identifiable {
    let id: UUID
    var existingID: UUID?
    var deckID: UUID
    var front: String
    var back: String
    var backDrawing: Data?
    var backMode: BackMode

    var isEditing: Bool { existingID != nil }

    var trimmedFront: String { front.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedBack: String { back.trimmingCharacters(in: .whitespacesAndNewlines) }

    var hasBackDrawing: Bool {
        guard let data = backDrawing else { return false }
        return !data.isEmpty
    }

    var isValid: Bool {
        guard !trimmedFront.isEmpty else { return false }
        switch backMode {
        case .text:    return !trimmedBack.isEmpty
        case .drawing: return hasBackDrawing
        }
    }

    init(
        existingID: UUID? = nil,
        deckID: UUID,
        front: String = "",
        back: String = "",
        backDrawing: Data? = nil,
        backMode: BackMode = .text
    ) {
        self.id = UUID()
        self.existingID = existingID
        self.deckID = deckID
        self.front = front
        self.back = back
        self.backDrawing = backDrawing
        self.backMode = backMode
    }

    static func edit(_ card: Card) -> CardDraft {
        let mode: BackMode = card.hasBackDrawing ? .drawing : .text
        return CardDraft(
            existingID: card.id,
            deckID: card.deck?.id ?? UUID(),
            front: card.front,
            back: card.back,
            backDrawing: card.backDrawing,
            backMode: mode
        )
    }
}
