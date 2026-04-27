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
        didSet { UserDefaults.standard.set(notificationHour, forKey: Keys.notificationHour) }
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

    // Cumulative count of "À revoir" ratings across all sessions. Drives the
    // permission-to-fail toast (brief §2.4) — shown once when this hits 3.
    var cumulativeAgainCount: Int = UserDefaults.standard.integer(forKey: Keys.cumulativeAgainCount) {
        didSet { UserDefaults.standard.set(cumulativeAgainCount, forKey: Keys.cumulativeAgainCount) }
    }

    // One-shot flag — the toast is shown at most once in the user's lifetime.
    var permissionToFailToastShown: Bool = UserDefaults.standard.bool(forKey: Keys.permissionToFailToastShown) {
        didSet { UserDefaults.standard.set(permissionToFailToastShown, forKey: Keys.permissionToFailToastShown) }
    }

    // ID of the last completion-screen sentence shown — avoids repeating the
    // same insight in consecutive sessions (brief §4.2).
    var lastShownInsightID: String? = UserDefaults.standard.string(forKey: Keys.lastShownInsightID) {
        didSet {
            if let value = lastShownInsightID {
                UserDefaults.standard.set(value, forKey: Keys.lastShownInsightID)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.lastShownInsightID)
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
        static let cumulativeAgainCount = "prefs.cumulativeAgainCount"
        static let permissionToFailToastShown = "prefs.permissionToFailToastShown"
        static let lastShownInsightID = "prefs.lastShownInsightID"
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
