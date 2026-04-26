import SwiftUI
import WidgetKit

struct MemoireWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: AppConstants.Widget.kind,
            provider: MemoireWidgetProvider()
        ) { entry in
            MemoireWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetChrome.background
                }
        }
        .configurationDisplayName("Mémoire")
        .description("Vos cartes à réviser, en un coup d'œil.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    MemoireWidget()
} timeline: {
    MemoireWidgetEntry.preview
    MemoireWidgetEntry(
        date: Date(),
        snapshot: WidgetSnapshot(
            hasAnyDeck: true, dueNow: 0, reviewedToday: 12, totalToday: 12,
            nextDueDate: nil, laterTodayCount: 0, streakDays: 7,
            generatedAt: Date(), schemaVersion: WidgetSnapshot.currentSchemaVersion
        )
    )
    MemoireWidgetEntry(
        date: Date(),
        snapshot: WidgetSnapshot(
            hasAnyDeck: true, dueNow: 0, reviewedToday: 5, totalToday: 5,
            nextDueDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
            laterTodayCount: 8, streakDays: 7,
            generatedAt: Date(), schemaVersion: WidgetSnapshot.currentSchemaVersion
        )
    )
    MemoireWidgetEntry(date: Date(), snapshot: nil)
}
