import Foundation
import SwiftUI

extension EnvironmentValues {
    @Entry var appPreferences: AppPreferences = .shared
}

@Observable
final class AppPreferences {
    static let shared = AppPreferences()

    var hasOnboarded: Bool = UserDefaults.standard.bool(forKey: Keys.hasOnboarded) {
        didSet { UserDefaults.standard.set(hasOnboarded, forKey: Keys.hasOnboarded) }
    }

    var calmMode: Bool = UserDefaults.standard.bool(forKey: Keys.calmMode) {
        didSet { UserDefaults.standard.set(calmMode, forKey: Keys.calmMode) }
    }

    var notificationHour: Int = UserDefaults.standard.integer(forKey: Keys.notificationHour, default: 18) {
        didSet {
            UserDefaults.standard.set(notificationHour, forKey: Keys.notificationHour)
            let hour = notificationHour
            Task { @MainActor in await NotificationScheduler.scheduleDaily(hour: hour) }
        }
    }

    var dailyNewCards: Int = UserDefaults.standard.integer(forKey: Keys.dailyNewCards, default: 10) {
        didSet { UserDefaults.standard.set(dailyNewCards, forKey: Keys.dailyNewCards) }
    }

    var firstName: String? = UserDefaults.standard.sanitizedString(forKey: Keys.firstName, maxLength: AppConstants.User.firstNameMaxLength) {
        didSet {
            if let value = Self.sanitize(firstName) {
                UserDefaults.standard.set(value, forKey: Keys.firstName)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.firstName)
            }
        }
    }

    static func sanitize(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return String(trimmed.prefix(AppConstants.User.firstNameMaxLength))
    }

    private enum Keys {
        static let hasOnboarded = "prefs.hasOnboarded"
        static let calmMode = "prefs.calmMode"
        static let notificationHour = "prefs.notificationHour"
        static let dailyNewCards = "prefs.dailyNewCards"
        static let firstName = "prefs.firstName"
    }
}

private extension UserDefaults {
    func integer(forKey key: String, default defaultValue: Int) -> Int {
        object(forKey: key) == nil ? defaultValue : integer(forKey: key)
    }

    func sanitizedString(forKey key: String, maxLength: Int) -> String? {
        guard let raw = string(forKey: key) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxLength))
    }
}
