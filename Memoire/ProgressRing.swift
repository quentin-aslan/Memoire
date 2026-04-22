import SwiftUI

struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 240
    var lineWidth: CGFloat = 16

    private var goldGradient: LinearGradient {
        LinearGradient(
            colors: [.goldLight, .gold, .goldDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    goldGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
