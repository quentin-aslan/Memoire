import SwiftUI

extension EnvironmentValues {
    @Entry var widgetLaunch: WidgetLaunchCoordinator = .shared
}

// Carries pending actions from a widget tap (deep-link) to the screen that
// can fulfil them. HomeScreen consumes .startReview after the app is foreground.
@Observable
final class WidgetLaunchCoordinator {
    static let shared = WidgetLaunchCoordinator()

    var pendingAction: Action?

    enum Action: Equatable {
        case startReview
    }

    func consume() -> Action? {
        let action = pendingAction
        pendingAction = nil
        return action
    }
}
