import Foundation
import SwiftUI

struct DeckDraft: Equatable, Identifiable {
    let id: UUID
    var existingID: UUID?
    var name: String
    var color: String

    var isEditing: Bool { existingID != nil }
    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isValid: Bool { !trimmedName.isEmpty }

    init(existingID: UUID? = nil, name: String = "", color: String = Color.goldHex) {
        self.id = UUID()
        self.existingID = existingID
        self.name = name
        self.color = color
    }

    static func edit(_ deck: Deck) -> DeckDraft {
        DeckDraft(existingID: deck.id, name: deck.name, color: deck.color ?? Color.goldHex)
    }
}
