import Foundation
import OSLog
import UserNotifications

enum NotificationScheduler {
    static let dailyID = AppConstants.Notifications.dailyReviewID
    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "NotificationScheduler")

    @MainActor
    static func scheduleDaily(hour: Int) async {
        let center = UNUserNotificationCenter.current()

        do {
            let initial = await center.notificationSettings()
            if initial.authorizationStatus == .notDetermined {
                _ = try await center.requestAuthorization(options: [.alert, .sound])
            }

            let settings = await center.notificationSettings()
            guard [.authorized, .provisional, .ephemeral]
                .contains(settings.authorizationStatus) else { return }

            center.removePendingNotificationRequests(withIdentifiers: [dailyID])

            let content = UNMutableNotificationContent()
            content.title = "Vos révisions vous attendent"
            content.body = "Quelques cartes aujourd'hui — 5 minutes suffisent."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: hour),
                repeats: true
            )

            try await center.add(
                UNNotificationRequest(identifier: dailyID, content: content, trigger: trigger)
            )
            logger.info("Daily notification scheduled at \(hour)h")
        } catch {
            logger.error("Failed to schedule notification: \(error.localizedDescription)")
        }
    }
}
