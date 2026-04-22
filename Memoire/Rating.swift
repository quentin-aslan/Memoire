import SwiftUI

enum Rating: Int, CaseIterable, Identifiable {
    case again = 1
    case good  = 3
    case easy  = 4

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .again: "À revoir"
        case .good:  "Moyen"
        case .easy:  "Facile"
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
