import SwiftUI

enum Rating: Int, CaseIterable, Identifiable {
    case again = 1
    case good  = 3
    case easy  = 4

    var id: Int { rawValue }

    // User-facing labels. "Moyen" / "Facile" were ambiguous in French (sounded
    // like a value judgment) — switched to "Connu" (I knew it, with effort) /
    // "Évident" (instantly, push the interval out) to clarify the FSRS intent.
    var label: String {
        switch self {
        case .again: "À revoir"
        case .good:  "Connu"
        case .easy:  "Évident"
        }
    }

    var glyph: String {
        switch self {
        case .again: "xmark"
        case .good:  "circle"
        case .easy:  "checkmark"
        }
    }

    var tint: Color {
        switch self {
        case .again: .stateAgain
        case .good:  .gold
        case .easy:  .stateEasy
        }
    }
}
