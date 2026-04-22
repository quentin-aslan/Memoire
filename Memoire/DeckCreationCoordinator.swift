import SwiftUI

extension EnvironmentValues {
    @Entry var deckCreation: DeckCreationCoordinator = .shared
}

@Observable
final class DeckCreationCoordinator {
    static let shared = DeckCreationCoordinator()

    var draft: DeckDraft?

    func open() {
        draft = DeckDraft()
    }

    func close() {
        draft = nil
    }
}
