import SwiftData
import SwiftUI

struct CardDetailScreen: View {
    let card: Card
    @Query private var reviewHistory: [Review]

    @State private var flipped: Bool = false
    @State private var showSoliditeSheet: Bool = false
    // Stable insight pick — chosen once on appear, doesn't re-tirage on scroll.
    @State private var insightSeed: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(card: Card) {
        self.card = card
        let cardId = card.id
        _reviewHistory = Query(
            filter: #Predicate<Review> { $0.cardID == cardId },
            sort: \Review.reviewedAt,
            order: .reverse
        )
    }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    heroSection
                    flipCard
                    metadataLine
                    nextReviewSection
                    statRow
                    if let palier = prochainPalierLine {
                        prochainPalierBlock(palier)
                    }
                    timelineSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Carte")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSoliditeSheet) {
            EditorialSheet.solidite()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear { insightSeed = Int.random(in: 0..<1000) }
    }

    // MARK: - Hero

    private var heroSection: some View {
        // Resolve once per render — color, word and insight all read from the same status.
        let s = CardStatusWord.resolve(card: card)
        return VStack(alignment: .leading, spacing: 8) {
            Text(s.word)
                .font(.serif(34, weight: .regular))
                .foregroundStyle(s.color)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(s.insight(seed: insightSeed))
                .font(.serif(17, weight: .regular))
                .foregroundStyle(Color.textReading.opacity(0.9))
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Flip card

    private var flipCard: some View {
        ZStack {
            cardFace(label: "QUESTION", text: card.front, weight: .semibold, size: 20, hint: "Tap pour retourner")
                .opacity(flipped ? 0 : 1)

            cardFaceBack
                .opacity(flipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
        }
        .rotation3DEffect(
            .degrees(flipped ? 180 : 0),
            axis: (0, 1, 0),
            perspective: 0.5
        )
        .contentShape(.rect)
        .onTapGesture {
            if reduceMotion {
                flipped.toggle()
            } else {
                withAnimation(.easeInOut(duration: 0.6)) { flipped.toggle() }
            }
        }
    }

    @ViewBuilder
    private var cardFaceBack: some View {
        if let drawingData = card.backDrawing, !drawingData.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                kicker("RÉPONSE")
                DrawingDisplay(data: drawingData)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
            .background(Color.bgCard, in: .rect(cornerRadius: 14))
            .shadow(color: .black.opacity(0.22), radius: 8, y: 2)
        } else {
            cardFace(label: "RÉPONSE", text: card.back, weight: .regular, size: 18, hint: nil)
        }
    }

    private func cardFace(label: String, text: String, weight: Font.Weight, size: CGFloat, hint: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            kicker(label)

            Text(text)
                .font(.serif(size, weight: weight))
                .foregroundStyle(Color.textReading)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let hint {
                Spacer(minLength: 6)
                HStack {
                    Spacer()
                    Text(hint)
                        .font(.sans(11))
                        .foregroundStyle(Color.textSecondary.opacity(0.6))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
        .background(Color.bgCard, in: .rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.22), radius: 8, y: 2)
    }

    private func kicker(_ text: String) -> some View {
        Text(text)
            .font(.sans(12, weight: .medium))
            .tracking(0.6)
            .foregroundStyle(Color.textSecondary)
    }

    // MARK: - Metadata + next review

    private var metadataLine: some View {
        Text(birthLabel)
            .font(.sans(12, weight: .medium))
            .foregroundStyle(Color.textSecondary)
    }

    private var nextReviewSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            kicker("PROCHAINE RÉVISION")
            Text(nextReviewLabel)
                .font(.serif(17, weight: .regular))
                .foregroundStyle(Color.textReading)
        }
    }

    // MARK: - Stat row

    private var statRow: some View {
        HStack(spacing: 0) {
            statCell(label: "SOLIDITÉ", value: stabilityLabel, showsInfo: true, action: { showSoliditeSheet = true })
            divider
            statCell(label: "VUES", value: "\(card.fsrsReps)", showsInfo: false, action: nil)
        }
        .background(Color.bgCard, in: .rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.16), radius: 6, y: 1)
    }

    private func statCell(label: String, value: String, showsInfo: Bool, action: (() -> Void)?) -> some View {
        let cell = VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.sans(11, weight: .medium))
                    .tracking(0.6)
                    .foregroundStyle(Color.textSecondary)
                if showsInfo {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Text(value)
                .font(.sans(17, weight: .regular))
                .foregroundStyle(Color.textReading)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .contentShape(.rect)

        return Group {
            if let action {
                Button(action: action) { cell }.buttonStyle(.plain)
            } else {
                cell
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.bgElevated)
            .frame(width: 0.5)
            .padding(.vertical, 8)
    }

    // MARK: - Prochain palier — shows the FSRS preview without naming the algorithm

    private var prochainPalierLine: AttributedString? {
        // Doctrine: only show for graduated review cards that aren't overdue.
        guard card.learningStep == -1,
              FSRSState(rawValue: card.fsrsState) == .review,
              let nextDue = card.nextReviewDate, nextDue > .now,
              card.fsrsLastReview != nil
        else { return nil }

        guard let projected = card.projectedNextReviewDate(rating: .good) else { return nil }
        let projectedDays = max(1, Int((projected.timeIntervalSince(.now) / 86_400).rounded()))
        let currentDays = max(1, Int(card.fsrsStability.rounded()))

        let projectedStr = formatDurationDays(projectedDays)
        let currentStr = formatDurationDays(currentDays)

        // Single source of truth for the rating label — Rating.swift owns the
        // user-facing word; we just reuse it bolded.
        let ratingWord = String(localized: Rating.good.label)
        var s = AttributedString(String(localized: "Si tu réponds "))
        var bold = AttributedString(ratingWord)
        bold.font = .serif(16, weight: .semibold)
        bold.foregroundColor = Color.gold
        s.append(bold)
        s.append(AttributedString(String(localized: ", prochaine révision dans \(projectedStr) au lieu de \(currentStr).")))
        return s
    }

    private func prochainPalierBlock(_ line: AttributedString) -> some View {
        Text(line)
            .font(.serif(16))
            .foregroundStyle(Color.textReading.opacity(0.92))
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.bgCard.opacity(0.55), in: .rect(cornerRadius: 12))
    }

    // MARK: - Timeline 10 notations colorées

    private var timelineSection: some View {
        // reviewHistory is sorted DESC; the timeline reads oldest left to newest right.
        // Materialize once — ForEach calls the cell builder 10 times.
        let recent = Array(reviewHistory.prefix(10).reversed())
        let pad = max(0, 10 - recent.count)
        return VStack(alignment: .leading, spacing: 10) {
            kicker("ÉVOLUTION RÉCENTE")
            HStack(spacing: 4) {
                ForEach(0..<10, id: \.self) { i in
                    timelineCell(index: i, recent: recent, pad: pad)
                }
            }
            .frame(height: 32)
        }
    }

    private func timelineCell(index: Int, recent: [Review], pad: Int) -> some View {
        let mappedIndex = index - pad
        let rating: Rating? = mappedIndex >= 0 ? Rating(rawValue: recent[mappedIndex].rating) : nil
        return RoundedRectangle(cornerRadius: 3)
            .fill(rating?.tint ?? Color.gold.opacity(0.10))
            .frame(maxWidth: .infinity)
    }

    // MARK: - Computed labels

    private var stabilityLabel: String {
        guard card.fsrsReps > 0 else { return "—" }
        return formatDurationDays(max(1, Int(card.fsrsStability.rounded())))
    }

    private var birthLabel: String {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: card.createdAt), to: cal.startOfDay(for: .now)).day ?? 0
        switch days {
        case 0:        return String(localized: "Apprise aujourd'hui")
        case 1:        return String(localized: "Apprise hier")
        case 2..<7:    return String(localized: "Apprise il y a \(days) jours")
        case 7..<14:   return String(localized: "Apprise il y a 1 semaine")
        case 14..<30:  return String(localized: "Apprise il y a \(days) jours")
        case 30..<60:  return String(localized: "Apprise il y a 1 mois")
        case 60..<365:
            let months = days / 30
            return String(localized: "Apprise il y a \(months) mois")
        default:       return String(localized: "Apprise il y a plus d'un an")
        }
    }

    private var nextReviewLabel: String {
        guard let next = card.nextReviewDate else { return String(localized: "À ta prochaine session") }
        let cal = Calendar.current
        let now = Date.now
        if next <= now { return String(localized: "Disponible maintenant") }
        if cal.isDateInToday(next) {
            let state = FSRSState(rawValue: card.fsrsState) ?? .new
            let isLearning = state == .learning || state == .relearning
            return isLearning ? next.formatted(.dateTime.hour().minute()) : String(localized: "Plus tard aujourd'hui")
        }
        if cal.isDateInTomorrow(next) {
            let hour = cal.component(.hour, from: next)
            return hour < 14 ? String(localized: "Demain matin") : String(localized: "Demain soir")
        }
        let startNow = cal.startOfDay(for: now)
        let startNext = cal.startOfDay(for: next)
        let days = cal.dateComponents([.day], from: startNow, to: startNext).day ?? 0
        let weekday = next.formatted(.dateTime.weekday(.wide))
        switch days {
        case 2..<7:
            return String(localized: "Dans \(days) jours · \(weekday)")
        case 7..<14:
            return String(localized: "La semaine prochaine")
        case 14..<30:
            return String(localized: "Dans environ \(days / 7) semaines")
        case 30..<90:
            return String(localized: "Dans environ \(days / 30) mois")
        case 90..<365:
            return String(localized: "Dans plusieurs mois")
        default:
            return String(localized: "L'an prochain")
        }
    }
}

// MARK: - Status word (private to CardDetailScreen)
//
// Resolves the FSRS state of a card to one of 5 public-facing words. The exact
// hex colors for the two transitional statuses (forming, toReviewSoon) live
// inside this enum — they aren't reused elsewhere in the app, so polluting the
// global Color palette would harm long-term maintainability.

private enum CardStatusWord {
    case toDiscover
    case forming
    case familiar
    case anchored
    case toReviewSoon

    static func resolve(card: Card) -> CardStatusWord {
        let r = card.currentRetrievability
        let s = card.fsrsStability
        let state = FSRSState(rawValue: card.fsrsState) ?? .new
        let overdue: Bool = {
            guard let due = card.nextReviewDate else { return false }
            return due.distance(to: .now) >= 86_400
        }()

        // Priority order: toReviewSoon > toDiscover > forming > familiar > anchored.
        // Skip the toReviewSoon check for new cards (no review yet → r is artificially 1.0).
        if state != .new, (r < 0.7 || overdue) { return .toReviewSoon }
        if state == .new { return .toDiscover }
        if state == .learning || state == .relearning { return .forming }
        if state == .review && s < AppConstants.FSRS.consolidatingStabilityDays { return .forming }
        if state == .review && s >= AppConstants.FSRS.solidStabilityDays && r >= 0.9 { return .anchored }
        return .familiar
    }

    var word: String {
        switch self {
        case .toDiscover:   return String(localized: "À découvrir")
        case .forming:      return String(localized: "En train de se former")
        case .familiar:     return String(localized: "Familière")
        case .anchored:     return String(localized: "Ancrée")
        case .toReviewSoon: return String(localized: "À revoir bientôt")
        }
    }

    var color: Color {
        switch self {
        case .toDiscover:   return Color.gold.opacity(0.6)
        // #C8B07A — soft warm tan, midway between gold and tertiary text.
        case .forming:      return Color(red: 200/255, green: 176/255, blue: 122/255)
        case .familiar:     return Color.gold
        case .anchored:     return Color.gold
        // #C8A88A — warm peach. Signals "needs attention" without alarm-coding (no red).
        case .toReviewSoon: return Color(red: 200/255, green: 168/255, blue: 138/255)
        }
    }

    func insight(seed: Int) -> String {
        let pool = insights
        return pool[abs(seed) % pool.count]
    }

    private var insights: [String] {
        switch self {
        case .toDiscover:
            return [
                String(localized: "Tu vas la rencontrer bientôt."),
                String(localized: "Cette carte attend son premier tour."),
                String(localized: "Première rencontre à venir.")
            ]
        case .forming:
            return [
                String(localized: "Cette carte cherche encore son rythme."),
                String(localized: "Elle revient souvent — c'est normal au début."),
                String(localized: "Mémoire l'espace progressivement.")
            ]
        case .familiar:
            return [
                String(localized: "Tu retrouves cette carte sans effort. Elle tient bien."),
                String(localized: "Elle revient maintenant à intervalle confortable."),
                String(localized: "Cette carte a trouvé son rythme.")
            ]
        case .anchored:
            return [
                String(localized: "Cette carte est solidement installée."),
                String(localized: "Tu peux compter sur elle longtemps."),
                String(localized: "Elle ne reviendra pas avant un bon moment.")
            ]
        case .toReviewSoon:
            return [
                String(localized: "Mémoire la ramène pour toi cette semaine."),
                String(localized: "Elle redemande un passage — rien de cassé."),
                String(localized: "Cette carte demande une nouvelle visite.")
            ]
        }
    }
}

