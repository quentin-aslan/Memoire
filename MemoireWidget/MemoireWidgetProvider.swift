import Foundation
import OSLog
import WidgetKit

struct MemoireWidgetProvider: TimelineProvider {
    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "WidgetProvider")
    private static let lookahead: TimeInterval = 6 * 3_600
    private static let fallbackInterval: TimeInterval = 3_600

    func placeholder(in context: Context) -> MemoireWidgetEntry {
        .preview
    }

    func getSnapshot(in context: Context, completion: @escaping (MemoireWidgetEntry) -> Void) {
        let entry = MemoireWidgetEntry(date: Date(), snapshot: WidgetSnapshot.read())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoireWidgetEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetSnapshot.read()
        var entries: [MemoireWidgetEntry] = [MemoireWidgetEntry(date: now, snapshot: snapshot)]

        // If a card becomes due in the next 6 hours, schedule a refresh exactly
        // then so state can transition C → A automatically without app launch.
        if let next = snapshot?.nextDueDate, next > now,
           next < now.addingTimeInterval(Self.lookahead) {
            entries.append(MemoireWidgetEntry(date: next, snapshot: snapshot))
            completion(Timeline(entries: entries, policy: .atEnd))
        } else {
            // Self-heal hourly — covers cases where the app never wakes up
            // (user reviews on another device, day rolls over, etc.).
            completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(Self.fallbackInterval))))
        }
    }
}
