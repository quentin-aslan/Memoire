import SwiftUI

// Length-encoded composition bar with 3 segments (Solides / En consolidation / À ramener).
// Single-hue gold luminance — the lighter the segment, the "more solid" the band.
//
// Colors are private to this component on purpose: they're an implementation
// detail of this visualization, not a semantic palette token. Keeping them
// here means the global Color+Tokens stays focused on app-wide tokens and
// adding/removing this component won't churn the palette.

struct CompositionBar: View {
    let solid: Int
    let consolidating: Int
    let toBack: Int
    var height: CGFloat = 8
    var corner: CGFloat = 4

    // #D4AF37 (Color.gold) → bright top of the band
    // #9A8556 — gold faded ~65%, mid-tone
    // #5A5550 — warm gray, the "needs attention" segment (no red, brief §0)
    private static let solidColor         = Color.gold
    private static let consolidatingColor = Color(red: 154/255, green: 133/255, blue: 86/255)
    private static let toBackColor        = Color(red: 90/255,  green: 85/255,  blue: 80/255)

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                segment(width: width(of: solid, in: geo.size.width), color: Self.solidColor)
                segment(width: width(of: consolidating, in: geo.size.width), color: Self.consolidatingColor)
                segment(width: width(of: toBack, in: geo.size.width), color: Self.toBackColor)
            }
            .clipShape(.rect(cornerRadius: corner))
        }
        .frame(height: height)
    }

    private func segment(width: CGFloat, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: width)
    }

    private func width(of count: Int, in total: CGFloat) -> CGFloat {
        let sum = solid + consolidating + toBack
        guard sum > 0 else { return 0 }
        return total * CGFloat(count) / CGFloat(sum)
    }

    static var legendColors: (solid: Color, consolidating: Color, toBack: Color) {
        (solidColor, consolidatingColor, toBackColor)
    }
}
