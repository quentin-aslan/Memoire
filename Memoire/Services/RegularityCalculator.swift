import Foundation
import SwiftData

struct RegularityCalculator {
    static func compute(reviews: [Review], referenceDate: Date = .now) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -AppConstants.Regularity.windowDays, to: referenceDate) ?? referenceDate
        let calendar = Calendar.current
        let distinctDays = Set(
            reviews
                .filter { $0.reviewedAt >= cutoff }
                .map { calendar.startOfDay(for: $0.reviewedAt) }
        )
        return distinctDays.count
    }

    // TDAH: anti-flicker matinal. Si l'utilisateur ouvre l'app à 8 h sans encore
    // avoir révisé aujourd'hui, on ancre le streak sur hier plutôt que de le
    // faire tomber à 0 avant le café.
    static func currentStreak(reviews: [Review], referenceDate: Date = .now) -> Int {
        let calendar = Calendar.current
        guard !reviews.isEmpty else { return 0 }

        let reviewedDays = Set(reviews.map { calendar.startOfDay(for: $0.reviewedAt) })
        let today = calendar.startOfDay(for: referenceDate)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }

        var cursor: Date
        if reviewedDays.contains(today) {
            cursor = today
        } else if reviewedDays.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var streak = 0
        while reviewedDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}
