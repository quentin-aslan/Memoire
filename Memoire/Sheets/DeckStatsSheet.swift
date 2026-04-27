import SwiftUI

// Stats sheet for a single deck. Two presentation detents:
//   - .medium: composition (bar + 3 labels) + "Cette semaine" sentence
//   - .large:  + 7-day forecast table + disclaimer
//
// The Fraîcheur ⓘ is the only entry point to that half-sheet — appears next
// to the "Cette semaine" sentence per brief §2.5/2.7.

struct DeckStatsSheet: View {
    let deck: Deck
    @Environment(\.dismiss) private var dismiss
    @State private var showFraicheurSheet: Bool = false

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE"
        return f
    }()

    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        compositionSection
                        thisWeekSection
                        forecastSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .sheet(isPresented: $showFraicheurSheet) {
            EditorialSheet.fraicheur()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Text(deck.name)
                .font(.serif(22, weight: .semibold))
                .foregroundStyle(Color.textReading)
                .lineLimit(1)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.leading, 24)
        .padding(.trailing, 4)
        .padding(.top, 8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.bgElevated).frame(height: 0.5)
        }
    }

    private var compositionSection: some View {
        let comp = deck.composition
        return VStack(alignment: .leading, spacing: 14) {
            kicker("COMPOSITION")
            CompositionBar(solid: comp.solid, consolidating: comp.consolidating, toBack: comp.toBack)

            VStack(spacing: 0) {
                row(label: "Stables", count: comp.solid, color: CompositionBar.legendColors.solid)
                Rectangle().fill(Color.bgElevated.opacity(0.5)).frame(height: 0.5)
                row(label: "En consolidation", count: comp.consolidating, color: CompositionBar.legendColors.consolidating)
                Rectangle().fill(Color.bgElevated.opacity(0.5)).frame(height: 0.5)
                row(label: "À ramener", count: comp.toBack, color: CompositionBar.legendColors.toBack)
            }
        }
    }

    private func row(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.sans(15))
                .foregroundStyle(Color.textReading)
            Spacer()
            Text("\(count) " + (count == 1 ? "carte" : "cartes"))
                .font(.sans(15, weight: .medium))
                .foregroundStyle(Color.textReading)
                .monospacedDigit()
        }
        .frame(height: 40)
    }

    private var thisWeekSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            kicker("CETTE SEMAINE")
            HStack(alignment: .top, spacing: 10) {
                Text(thisWeekSentence)
                    .font(.serif(17))
                    .foregroundStyle(Color.textReading)
                    .lineSpacing(2)
                Spacer()
                Button { showFraicheurSheet = true } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var thisWeekSentence: String {
        let n = deck.dueThisWeek()
        switch n {
        case 0: return "Rien à revoir cette semaine."
        case 1: return "Environ 1 carte à revoir cette semaine."
        default: return "Environ \(n) cartes à revoir cette semaine."
        }
    }

    private var forecastSection: some View {
        let counts = deck.forecastByDay(7)
        return VStack(alignment: .leading, spacing: 10) {
            kicker("LES 7 PROCHAINS JOURS")
            VStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    forecastRow(dayOffset: i, count: counts[i])
                    if i < 6 {
                        Rectangle().fill(Color.bgElevated.opacity(0.5)).frame(height: 0.5)
                    }
                }
            }

            Text("Mémoire ne prédit pas plus loin que 7 jours — au-delà, c'est trop incertain.")
                .font(.serif(14))
                .italic()
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(2)
                .padding(.top, 14)
        }
    }

    private func forecastRow(dayOffset: Int, count: Int) -> some View {
        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: .now) ?? .now
        let label = dayOffset == 0 ? "Aujourd'hui" : Self.weekdayFormatter.string(from: date).capitalized
        let valueText = count == 0 ? "—" : "~\(count) " + (count == 1 ? "carte" : "cartes")
        return HStack {
            Text(label)
                .font(.sans(15))
                .foregroundStyle(Color.textReading)
            Spacer()
            Text(valueText)
                .font(.sans(15))
                .foregroundStyle(count == 0 ? Color.textSecondary : Color.textReading)
                .monospacedDigit()
        }
        .frame(height: 38)
    }

    private func kicker(_ text: String) -> some View {
        Text(text)
            .font(.sans(12, weight: .medium))
            .tracking(0.6)
            .foregroundStyle(Color.textSecondary)
    }
}

