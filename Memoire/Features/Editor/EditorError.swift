import Foundation

enum EditorError: LocalizedError, Identifiable {
    case emptyField
    case saveFailed(String)
    case deckNotFound

    var id: String { errorDescription ?? "error" }

    var errorDescription: String? {
        switch self {
        case .emptyField:
            "Ce champ ne peut pas être vide."
        case .saveFailed(let message):
            "Échec de l'enregistrement : \(message)"
        case .deckNotFound:
            "Impossible de retrouver le paquet associé."
        }
    }
}
