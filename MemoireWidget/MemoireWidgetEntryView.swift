import SwiftUI
import WidgetKit

struct MemoireWidgetEntryView: View {
    let entry: MemoireWidgetEntry

    var body: some View {
        content
            // Clamp Dynamic Type so we don't fight minimumScaleFactor.
            .dynamicTypeSize(.large ... .xxLarge)
            .widgetURL(deepLink)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .dueNow(let dueNow, let reviewed, let total, let streak):
            DueNowView(dueNow: dueNow, reviewed: reviewed, total: total, streakDays: streak)
        case .upToDate(let streak):
            UpToDateView(streakDays: streak)
        case .laterToday(let date, let count, let streak):
            LaterTodayView(time: date, count: count, streakDays: streak)
        case .onboarding:
            OnboardingView()
        }
    }

    private var state: WidgetState {
        WidgetStateResolver.resolve(snapshot: entry.snapshot, now: entry.date)
    }

    private var deepLink: URL {
        switch state {
        case .dueNow:     return AppConstants.DeepLinks.review
        case .upToDate:   return AppConstants.DeepLinks.home
        case .laterToday: return AppConstants.DeepLinks.home
        case .onboarding: return AppConstants.DeepLinks.newDeck
        }
    }
}

enum WidgetState {
    case dueNow(dueNow: Int, reviewed: Int, total: Int, streak: Int)
    case upToDate(streak: Int)
    case laterToday(at: Date, count: Int, streak: Int)
    case onboarding
}

// Keep the decision tree out of the View so it can be unit-tested in the
// future without spinning up a SwiftUI environment.
enum WidgetStateResolver {
    private static let staleThreshold: TimeInterval = 86_400  // 24 h

    static func resolve(snapshot: WidgetSnapshot?, now: Date) -> WidgetState {
        // Fichier absent → premier lancement → D
        guard let s = snapshot else { return .onboarding }

        // Stale > 24 h → on n'affiche jamais un chiffre périmé ; D neutre
        if now.timeIntervalSince(s.generatedAt) > staleThreshold { return .onboarding }

        // Pas de deck → D
        guard s.hasAnyDeck else { return .onboarding }

        // Cartes dues maintenant → A
        if s.dueNow > 0 {
            return .dueNow(
                dueNow: s.dueNow,
                reviewed: s.reviewedToday,
                total: max(s.totalToday, 1),
                streak: s.streakDays
            )
        }

        // Carte due aujourd'hui mais pas encore → C
        if let next = s.nextDueDate,
           next > now,
           next < endOfToday(now) {
            return .laterToday(at: next, count: s.laterTodayCount, streak: s.streakDays)
        }

        // Sinon → B (à jour, prochaine carte demain ou plus tard)
        return .upToDate(streak: s.streakDays)
    }

    private static func endOfToday(_ now: Date) -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86_400)
        return calendar.startOfDay(for: tomorrow)
    }
}
