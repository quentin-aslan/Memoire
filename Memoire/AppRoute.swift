import Foundation

enum AppRoute: Hashable {
    case deckDetail(UUID)
    case cardDetail(UUID)
    case review
    case complete
}
