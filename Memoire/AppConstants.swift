import Foundation

enum AppConstants {
    enum Logging {
        static let subsystem = "com.memoire.app"
    }

    enum Notifications {
        static let dailyReviewID = "memoire.dailyReview"
    }

    enum Regularity {
        // Matches the 30-day window shown in HomeScreen's progress ring label
        static let windowDays = 30
    }

    enum FSRS {
        static let defaultRetention: Double = 0.90
        static let minRetention: Double     = 0.80
        static let maxRetention: Double     = 0.95

        // Stability bands used for the deck composition bar (Stables / En consolidation
        // / À ramener) and the "Prochain palier" framing on CardDetailScreen. Aligned
        // with Anki "mature" cards convention (≥21d) and the brief §1.10.
        static let solidStabilityDays: Double         = 21
        static let consolidatingStabilityDays: Double = 7

        // TDAH: prior honnête pour estimer la durée d'une session. 8-12 s/carte en
        // steady-state, on vise 12 pour sous-promettre (évite la honte quand on déborde).
        static let avgSecondsPerCard: Double = 12
    }

    enum User {
        static let firstNameMaxLength = 20
    }

    enum Onboarding {
        static let pageCount = 5
    }

    enum LearningSteps {
        static let steps: [TimeInterval] = [600, 3600, 86400]  // 10 min, 1 h, 1 day
    }

    enum Support {
        static let contactEmail = "contact@quentinaslan.com"
    }

    enum Backup {
        static let currentSchemaVersion = 1
        static let fileExtension = "memoire.json"
    }

    enum Widget {
        static let appGroupID = "group.com.quentinaslan.Memoire"
        static let snapshotFile = "widget-snapshot.json"
        static let kind = "MemoireWidget"
    }

    enum DeepLinks {
        static let scheme = "memoire"
        static let review = URL(string: "\(scheme)://review")!
        static let home = URL(string: "\(scheme)://home")!
        static let newDeck = URL(string: "\(scheme)://decks/new")!
    }
}
