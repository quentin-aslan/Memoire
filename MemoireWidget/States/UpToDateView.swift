import SwiftUI

// State B — coche or + « À jour ». Halo doré subtil pour récompense sensorielle.
struct UpToDateView: View {
    let streakDays: Int

    var body: some View {
        ZStack {
            // Subtle gold halo behind the checkmark
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.gold.opacity(0.06), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .offset(y: -10)

            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Color.gold.opacity(0.2), lineWidth: 1.2)
                        .frame(width: 44, height: 44)

                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.gold)
                }

                Text("À jour")
                    .font(.serif(24))
                    .tracking(-0.4)
                    .foregroundStyle(Color.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.bottom, 18)

            VStack {
                Spacer()
                WidgetFooter(streakDays: streakDays)
                    .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
