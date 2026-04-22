import Foundation

// Maps the Int stored in Card.fsrsState to the FSRS learning phase.
// Storage stays Int to avoid a SwiftData schema migration.
enum FSRSState: Int {
    case new        = 0
    case learning   = 1
    case review     = 2
    case relearning = 3
}
