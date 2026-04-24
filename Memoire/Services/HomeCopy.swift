import Foundation

// Pure formatters for the Accueil screen. Kept as static funcs so each piece
// is testable in isolation and can mutate independently (e.g. sessionTimeEstimate
// will become per-user adaptive once telemetry lands — see ADR-0008).
enum HomeCopy {
    static func greeting(at date: Date = .now, firstName: String?) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        let base = salutation(forHour: hour)
        if let name = AppPreferences.sanitize(firstName) {
            return "\(base), \(name)."
        }
        return base
    }

    static func salutation(forHour hour: Int) -> String {
        switch hour {
        case 5...11:  return "Bonjour"
        case 12...17: return "Bon après-midi"
        case 18...23: return "Bonsoir"
        default:      return "Bonne nuit"
        }
    }

    static func ctaLabel(cardsDue: Int) -> String {
        switch cardsDue {
        case 1:     return "Réviser une carte"
        case 2...5: return "Réviser \(cardsDue) cartes"
        default:    return "Réviser"
        }
    }

    static func ctaSubtitle(cardsDue: Int, at date: Date = .now) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        // TDAH: 0-4 h → on retire l'urgence. L'hyperfocus nocturne se retourne
        // vite contre l'utilisateur, la session peut attendre le matin.
        if (0...4).contains(hour) {
            return "À faire quand vous voulez."
        }
        let noun = cardsDue == 1 ? "carte" : "cartes"
        return "\(sessionTimeEstimate(cardsDue: cardsDue)) · \(cardsDue) \(noun)"
    }

    static func sessionTimeEstimate(cardsDue: Int) -> String {
        // TDAH: cap anti-ancrage. Au-delà de 100 cartes, "20 min ou plus" évite
        // d'afficher un chiffre effrayant qui déclenche l'évitement.
        if cardsDue > 100 { return "≈ 20 minutes ou plus" }

        let seconds = Double(cardsDue) * AppConstants.FSRS.avgSecondsPerCard
        if seconds < 60 { return "≈ 1 minute" }

        if seconds <= 600 {
            let minutes = max(1, Int((seconds / 60).rounded()))
            return "≈ \(minutes) \(minutes == 1 ? "minute" : "minutes")"
        }

        let fiveMinChunks = max(1, Int((seconds / 300).rounded()))
        return "≈ \(fiveMinChunks * 5) minutes"
    }

    static func regularitySubtitle(streak: Int, windowDays: Int) -> String {
        switch streak {
        case 0:  return "\(windowDays) derniers jours"
        case 1:  return "1 jour d'affilée · \(windowDays) derniers jours"
        default: return "\(streak) jours d'affilée · \(windowDays) derniers jours"
        }
    }

    static func nextReviewHint(nextDueDate: Date?, referenceDate: Date = .now) -> String? {
        guard let date = nextDueDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let target = calendar.startOfDay(for: date)
        guard let days = calendar.dateComponents([.day], from: today, to: target).day, days >= 1 else {
            return nil
        }

        switch days {
        case 1:       return "Prochaine révision demain."
        case 7:       return "Prochaine révision dans une semaine."
        case 2...14:  return "Prochaine révision dans \(days) jours."
        default:      return "Prochaine révision le \(shortDateFormatter.string(from: date))."
        }
    }

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "d MMMM"
        return f
    }()
}
