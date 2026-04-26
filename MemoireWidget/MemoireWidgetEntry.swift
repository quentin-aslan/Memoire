import Foundation
import WidgetKit

struct MemoireWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?

    // Used by placeholder() and gallery preview — matches the design mockup
    // (12 due, 5 reviewed of 17, 3-day streak).
    static let preview = MemoireWidgetEntry(
        date: Date(),
        snapshot: WidgetSnapshot(
            hasAnyDeck: true,
            dueNow: 12,
            reviewedToday: 5,
            totalToday: 17,
            nextDueDate: nil,
            laterTodayCount: 0,
            streakDays: 3,
            generatedAt: Date(),
            schemaVersion: WidgetSnapshot.currentSchemaVersion
        )
    )
}
