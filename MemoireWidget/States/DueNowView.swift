import SwiftUI

// State A — anneau dominant, chiffre or hero centré, ratio « 5 / 17 », footer.
struct DueNowView: View {
    let dueNow: Int
    let reviewed: Int
    let total: Int
    let streakDays: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(reviewed) / Double(total)
    }

    var body: some View {
        ZStack {
            WidgetRing(progress: progress, diameter: 116, lineWidth: 6)

            VStack(spacing: 0) {
                Text("\(dueNow)")
                    .font(.serif(52, weight: .semibold))
                    .tracking(-1.3)
                    .foregroundStyle(Color.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("CARTES")
                    .font(.sans(10))
                    .tracking(0.6)
                    .foregroundStyle(Color.white.opacity(0.38))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 1)
            }

            VStack {
                Spacer()
                Text("\(reviewed) / \(total) révisées")
                    .font(.sans(10))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.bottom, 30)

                WidgetFooter(streakDays: streakDays)
                    .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
