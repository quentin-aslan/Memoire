import SwiftUI

// Shared visual primitives for every widget state.
// Inlined here (no Components/ subfolder) — three small views don't justify one.
enum WidgetChrome {
    // Radial gradient + thin hairline. The hairline kills the "black hole"
    // effect on light wallpapers without compromising the dark luxury look.
    static var background: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: "#1c1c1c"), Color(hex: "#0A0A0A")],
                center: UnitPoint(x: 0.38, y: 0.28),
                startRadius: 0,
                endRadius: 180
            )

            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        }
    }
}

// "Mémoire · 3j" — middle-dot glyph (not a drawn circle: sub-pixel on @2x).
struct WidgetFooter: View {
    let streakDays: Int?

    var body: some View {
        HStack(spacing: 4) {
            Text("Mémoire")
                .font(.sans(9))
                .foregroundStyle(Color.white.opacity(0.22))

            if let streak = streakDays, streak > 0 {
                Text("·")
                    .font(.sans(9))
                    .foregroundStyle(Color.white.opacity(0.15))
                Text("\(streak)j")
                    .font(.sans(9, weight: .medium))
                    .foregroundStyle(Color.gold.opacity(0.5))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

// Gold ring with track (track at 8% gold, foreground at 88% gold).
// `progress` clamped to [0, 1].
struct WidgetRing: View {
    let progress: Double
    var diameter: CGFloat = 116
    var lineWidth: CGFloat = 6

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gold.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    Color.gold.opacity(0.88),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: diameter, height: diameter)
    }
}
