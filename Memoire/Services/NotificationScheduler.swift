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
        do {
            guard try await isAuthorized(promptIfNeeded: true) else { return }

            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: (0..<maxSlots).map(slotID))

            let descriptor = FetchDescriptor<Card>(predicate: #Predicate { !$0.isSoftDeleted })
            let activeCards = try context.fetch(descriptor)
            let futureDates = DailyQueue.futureDueDates(allCards: activeCards, days: maxSlots)

            guard !futureDates.isEmpty else {
                logger.info("No cards due in the next \(maxSlots) days — no notifications scheduled")
                return
            }

            let now = Date.now
            var scheduled = 0

            for (index, entry) in futureDates.enumerated() {
                guard let targetDate = slotDate(for: entry.date, hour: prefs.notificationHour),
                      targetDate > now else { continue }

                let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: targetDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: slotID(index),
                    content: makeContent(count: entry.count, firstName: prefs.firstName),
                    trigger: trigger
                )

                try await center.add(request)
                scheduled += 1
            }

            logger.info("Scheduled \(scheduled) notification(s) over the next \(maxSlots) days")
        } catch {
            logger.error("Failed to schedule notifications: \(error.localizedDescription)")
        }
    }

    private static func slotID(_ index: Int) -> String { "\(idPrefix).\(index)" }

    private static func slotDate(for day: Date, hour: Int) -> Date? {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day)
    }

    private static func isAuthorized(promptIfNeeded: Bool) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let initial = await center.notificationSettings()
        let status: UNAuthorizationStatus
        if promptIfNeeded, initial.authorizationStatus == .notDetermined {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
            status = await center.notificationSettings().authorizationStatus
        } else {
            status = initial.authorizationStatus
        }
        return [.authorized, .provisional, .ephemeral].contains(status)
    }

    private static func makeContent(count: Int, firstName: String?) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title(firstName: firstName)
        content.body = body(count: count)
        content.sound = .default
        return content
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

    #if DEBUG
    private static let testID = "\(idPrefix).test"

    /// Returns true if a preview was scheduled, false if there's nothing to preview
    /// (no future due cards in the same horizon `refresh()` uses). Mirrors the exact
    /// guard in `refresh()` so test == prod.
    @MainActor
    static func sendTestNotification(context: ModelContext, prefs: AppPreferences) async -> Bool {
        do {
            guard try await isAuthorized(promptIfNeeded: false) else {
                logger.info("Test notification skipped — notifications not authorized")
                return false
            }

            let descriptor = FetchDescriptor<Card>(predicate: #Predicate { !$0.isSoftDeleted })
            let activeCards = try context.fetch(descriptor)
            let now = Date.now

            guard let next = DailyQueue.futureDueDates(allCards: activeCards, days: maxSlots)
                .first(where: { entry in
                    guard let target = slotDate(for: entry.date, hour: prefs.notificationHour) else { return false }
                    return target > now
                }) else {
                logger.info("Test notification skipped — no future cards to preview")
                return false
            }

            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [testID])

            let request = UNNotificationRequest(
                identifier: testID,
                content: makeContent(count: next.count, firstName: prefs.firstName),
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            )
            try await center.add(request)
            logger.info("Test notification scheduled in 5 seconds (count: \(next.count))")
            return true
        } catch {
            logger.error("Failed to schedule test notification: \(error.localizedDescription)")
            return false
        }
    }
    #endif
}
