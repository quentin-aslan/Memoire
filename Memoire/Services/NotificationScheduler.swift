import Foundation
import OSLog
import SwiftData
import UserNotifications

enum NotificationScheduler {
    private static let idPrefix = AppConstants.Notifications.dailyReviewIDPrefix
    private static let maxSlots = 30
    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "NotificationScheduler")

    @MainActor
    static func refresh(context: ModelContext, prefs: AppPreferences) async {
        let center = UNUserNotificationCenter.current()

        do {
            let initial = await center.notificationSettings()
            if initial.authorizationStatus == .notDetermined {
                _ = try await center.requestAuthorization(options: [.alert, .sound])
            }

            let settings = await center.notificationSettings()
            guard [.authorized, .provisional, .ephemeral]
                .contains(settings.authorizationStatus) else { return }

            let slotIDs = (0..<maxSlots).map { "\(idPrefix).\($0)" }
            center.removePendingNotificationRequests(withIdentifiers: slotIDs)

            let allCards = (try? context.fetch(FetchDescriptor<Card>())) ?? []
            let futureDates = DailyQueue.futureDueDates(allCards: allCards, days: maxSlots)

            guard !futureDates.isEmpty else {
                logger.info("No cards due in the next \(maxSlots) days — no notifications scheduled")
                return
            }

            let now = Date.now
            var scheduled = 0

            for (index, entry) in futureDates.prefix(maxSlots).enumerated() {
                guard let targetDate = targetDate(for: entry.date, hour: prefs.notificationHour),
                      targetDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = title(firstName: prefs.firstName)
                content.body = body(count: entry.count)
                content.sound = .default

                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour],
                    from: targetDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: "\(idPrefix).\(index)", content: content, trigger: trigger)

                try await center.add(request)
                scheduled += 1
            }

            logger.info("Scheduled \(scheduled) notification(s) over the next \(maxSlots) days")
        } catch {
            logger.error("Failed to schedule notifications: \(error.localizedDescription)")
        }
    }

    private static func targetDate(for day: Date, hour: Int) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components)
    }

    private static func title(firstName: String?) -> String {
        if let name = AppPreferences.sanitize(firstName) {
            return String(localized: "\(name), vos révisions vous attendent")
        }
        return String(localized: "Vos révisions vous attendent")
    }

    private static func body(count: Int) -> String {
        let estimate = HomeCopy.sessionTimeEstimate(cardsDue: count)
        return String(localized: "\(estimate) · \(count) cartes")
    }
}
