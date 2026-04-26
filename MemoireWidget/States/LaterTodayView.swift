import SwiftUI

// State C — « Prochaine » + heure hero (14h30) + nombre de cartes.
struct LaterTodayView: View {
    let time: Date
    let count: Int
    let streakDays: Int

    // French manual format — Text(date, style: .time) renders "14:30" not "14h30".
    private var formattedTime: String {
        let calendar = Calendar.current
        let h = calendar.component(.hour, from: time)
        let m = calendar.component(.minute, from: time)
        return String(format: "%dh%02d", h, m)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Text("PROCHAINE")
                    .font(.sans(9))
                    .tracking(1.1)
                    .foregroundStyle(Color.white.opacity(0.30))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.bottom, 10)

                Text(formattedTime)
                    .font(.serif(34, weight: .semibold))
                    .tracking(-1.0)
                    .foregroundStyle(Color.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Rectangle()
                    .fill(Color.gold.opacity(0.2))
                    .frame(width: 22, height: 1)
                    .padding(.top, 12)
                    .padding(.bottom, 9)

                Text(count == 1 ? "1 carte" : "\(count) cartes")
                    .font(.sans(11))
                    .foregroundStyle(Color.white.opacity(0.38))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.bottom, 16)

            VStack {
                Spacer()
                WidgetFooter(streakDays: streakDays)
                    .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
