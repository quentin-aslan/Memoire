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

        // Thresholds for the Facile / Moyenne / Difficile labels in CardDetailScreen
        static let easyDifficultyThreshold: Double   = 4.0
        static let mediumDifficultyThreshold: Double = 7.0

        // TDAH: prior honnête pour estimer la durée d'une session. 8-12 s/carte en
        // steady-state, on vise 12 pour sous-promettre (évite la honte quand on déborde).
        static let avgSecondsPerCard: Double = 12
    }

    enum User {
        static let firstNameMaxLength = 20
    }

    enum Onboarding {
        static let pageCount = 4
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
}
