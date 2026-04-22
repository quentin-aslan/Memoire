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
}
