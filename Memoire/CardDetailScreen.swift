import SwiftData
import SwiftUI

struct CardDetailScreen: View {
    let card: Card
    @Query private var reviewHistory: [Review]

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
                VStack(alignment: .leading, spacing: 24) {
                    contentSection
                    planningSection
                    fsrsStatsSection
                    historySection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Carte")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionKicker("QUESTION")

            Text(card.front)
                .font(.serif(22, weight: .regular))
                .foregroundStyle(Color.textReading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.surfaceElevated, in: .rect(cornerRadius: 16))

            sectionKicker("RÉPONSE")

            backContentView
        }
    }

    @ViewBuilder
    private var backContentView: some View {
        if let drawingData = card.backDrawing, !drawingData.isEmpty {
            DrawingDisplay(data: drawingData)
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .padding(16)
                .background(Color.bgCard, in: .rect(cornerRadius: 16))
        } else {
            Text(card.back)
                .font(.serif(18, weight: .regular))
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.bgCard, in: .rect(cornerRadius: 16))
        }
    }

    private var planningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionKicker("PROCHAINE RÉVISION")

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(nextReviewLabel)
                        .font(.serif(26, weight: .medium))
                        .foregroundStyle(Color.gold)
                    Text(nextReviewSub)
                        .font(.sans(13))
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Image(systemName: "calendar")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.goldSubtle)
                    .frame(width: 48, height: 48)
                    .background(Color.goldSubtle, in: .circle)
            }
            .padding(18)
            .background(Color.bgCard, in: .rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.goldSubtle, lineWidth: 0.5)
            )
        }
    }

    private var difficultyLabel: String {
        guard card.fsrsReps > 0 else { return "–" }
        switch card.fsrsDifficulty {
        case ..<AppConstants.FSRS.easyDifficultyThreshold:   return "Facile"
        case ..<AppConstants.FSRS.mediumDifficultyThreshold: return "Moyenne"
        default:                                              return "Difficile"
        }
    }

    private var stateLabel: String {
        switch FSRSState(rawValue: card.fsrsState) ?? .new {
        case .new:        return "Nouvelle"
        case .learning:   return "Apprentissage"
        case .review:     return "Révision"
        case .relearning: return "Réapprentissage"
        }
    }

    private var stabilityLabel: String {
        guard card.fsrsReps > 0 else { return "–" }
        let d = Int(card.fsrsStability.rounded())
        if d < 1 { return "< 1 jour sans oublier" }
        return "~\(d) jour\(d >= 2 ? "s" : "") sans oublier"
    }

    private var fsrsStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionKicker("MÉMORISATION")

            VStack(spacing: 0) {
                statRow(label: "État", value: stateLabel)
                divider
                statRow(label: "Difficulté", value: difficultyLabel)
                divider
                statRow(label: "Mémorisation", value: stabilityLabel)
                divider
                statRow(label: "Révisions", value: "\(card.fsrsReps)")
                divider
                statRow(label: "Erreurs", value: "\(card.fsrsLapses)")
            }
            .background(Color.bgCard, in: .rect(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private var historySection: some View {
        if !reviewHistory.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionKicker("HISTORIQUE")

                VStack(spacing: 8) {
                    ForEach(reviewHistory.prefix(10)) { review in
                        historyRow(review)
                    }
                }
            }
        }
    }

    private func historyRow(_ review: Review) -> some View {
        let rating = Rating(rawValue: review.rating)

        return HStack(spacing: 12) {
            Circle()
                .fill(rating?.tint ?? .textTertiary)
                .frame(width: 8, height: 8)

            Text(rating?.label ?? "—")
                .font(.sans(14, weight: .semibold))
                .foregroundStyle(rating?.tint ?? .textSecondary)

            Spacer()

            Text(Self.historyFormatter.string(from: review.reviewedAt))
                .font(.sans(12))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.bgCard, in: .rect(cornerRadius: 10))
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.sans(14))
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.sans(14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.04))
            .frame(height: 0.5)
            .padding(.leading, 18)
    }

    private func sectionKicker(_ text: String) -> some View {
        Text(text)
            .font(.sans(11, weight: .semibold))
            .tracking(1.8)
            .foregroundStyle(Color.gold)
    }

    private var nextReviewLabel: String {
        guard let next = card.nextReviewDate else { return "Nouvelle carte" }
        if next <= .now { return "Maintenant" }
        let cal = Calendar.current
        if cal.isDateInToday(next) { return "Aujourd'hui" }
        if cal.isDateInTomorrow(next) { return "Demain" }
        return Self.longFormatter.string(from: next)
    }

    private var nextReviewSub: String {
        guard let next = card.nextReviewDate else { return "Pas encore révisée" }
        if next <= .now { return "Carte due" }
        let cal = Calendar.current
        if cal.isDateInToday(next) {
            // Show exact time only for learning/relearning — review cards are due at day granularity
            let state = FSRSState(rawValue: card.fsrsState) ?? .new
            let isLearning = state == .learning || state == .relearning
            return isLearning ? Self.timeFormatter.string(from: next) : "Plus tard"
        }
        if cal.isDateInTomorrow(next) {
            return Self.shortDateFormatter.string(from: next)
        }
        let startNow = cal.startOfDay(for: .now)
        let startNext = cal.startOfDay(for: next)
        let days = cal.dateComponents([.day], from: startNow, to: startNext).day ?? 0
        return "Dans \(days) jours"
    }

    private static let longFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE d MMMM"
        return f
    }()

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEE d MMM"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "HH'h'mm"
        return f
    }()

    private static let historyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "d MMM · HH:mm"
        return f
    }()
}
