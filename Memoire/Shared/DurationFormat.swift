import Foundation

// French human-friendly duration label used by both CardDetailScreen and
// DeckDetailScreen. Buckets are FSRS-friendly — never expose an exact day
// count past 6 days (the prefix "~" makes it clear that the projection is
// approximate, which matches how FSRS actually schedules).
//
// See `docs/v4-copy-and-algorithms.md` §5 (Truncation des durées) — keep
// this function and the doc in sync.
func formatDurationDays(_ days: Int) -> String {
    switch days {
    case ..<1:      return "moins d'un jour"
    case 1:         return "1 jour"
    case 2..<7:     return "~\(days) jours"
    case 7..<14:    return "~1 semaine"
    case 14..<21:   return "~2 semaines"
    case 21..<30:   return "~3 semaines"
    case 30..<60:   return "~1 mois"
    case 60..<90:   return "~2 mois"
    case 90..<180:  return "~3 mois"
    case 180..<365: return "~6 mois"
    case 365..<730: return "~1 an"
    default:        return "plus d'un an"
    }
}
