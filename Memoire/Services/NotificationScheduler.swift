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
                guard let targetDate = Calendar.current.date(bySettingHour: prefs.notificationHour, minute: 0, second: 0, of: entry.date),
                      targetDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = title(firstName: prefs.firstName)
                content.body = body(count: entry.count)
                content.sound = .default

                let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: targetDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: slotID(index), content: content, trigger: trigger)

                try await center.add(request)
                scheduled += 1
            }

            logger.info("Scheduled \(scheduled) notification(s) over the next \(maxSlots) days")
        } catch {
            logger.error("Failed to schedule notifications: \(error.localizedDescription)")
        }
    }

    private static func slotID(_ index: Int) -> String { "\(idPrefix).\(index)" }

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

    @MainActor
    static func sendTestNotification(context: ModelContext, prefs: AppPreferences) async {
        do {
            guard try await isAuthorized(promptIfNeeded: false) else {
                logger.info("Test notification skipped — notifications not authorized")
                return
            }

            let descriptor = FetchDescriptor<Card>(predicate: #Predicate { !$0.isSoftDeleted })
            let activeCards = try context.fetch(descriptor)
            let dueToday = DailyQueue.build(allCards: activeCards, allReviews: [], dailyNewCards: 0).count
            let count = dueToday > 0 ? dueToday : prefs.dailyNewCards

            let content = UNMutableNotificationContent()
            content.title = title(firstName: prefs.firstName)
            content.body = body(count: count)
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: testID, content: content, trigger: trigger)

            try await UNUserNotificationCenter.current().add(request)
            logger.info("Test notification scheduled in 5 seconds (count: \(count))")
        } catch {
            logger.error("Failed to schedule test notification: \(error.localizedDescription)")
        }
    }
    #endif
}
