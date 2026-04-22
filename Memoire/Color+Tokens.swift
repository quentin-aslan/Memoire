import SwiftUI

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension Color {
    static let bgPrimary      = Color(hex: "#1C1C1E")
    static let bgHairline     = Color(red: 84/255, green: 84/255, blue: 88/255).opacity(0.45)
    static let bgCard         = Color(hex: "#2C2C2E")
    static let bgElevated     = Color(hex: "#3A3A3C")
    static let surfaceElevated = Color(hex: "#232325")
    static let surfaceRaised   = Color(hex: "#2A2A2C")

    static let textPrimary   = Color(hex: "#F5F5F7")
    static let textReading   = Color(hex: "#F2EDE4")
    static let textSecondary = Color.white.opacity(0.60)
    static let textTertiary  = Color.white.opacity(0.30)

    static let onGold      = Color(hex: "#1A1405")
    static let goldHex     = "#D4AF37"
    static let gold        = Color(hex: goldHex)
    static let goldOnGlass = Color(hex: "#E6C558")
    static let goldLight   = Color(hex: "#E5C564")
    static let goldDark    = Color(hex: "#B8942E")
    static let goldMuted   = Color(hex: "#A8892B")
    static let goldTint     = Color(hex: goldHex).opacity(0.14)
    static let goldTintSoft = Color(hex: goldHex).opacity(0.08)
    static let goldSubtle   = Color(hex: goldHex).opacity(0.12)

    static let stateAgain = Color(hex: "#F7A58C")
    static let stateHard  = Color(hex: "#E8A867")
    static let stateGood  = Color(hex: "#D4AF37")
    static let stateEasy  = Color(hex: "#4ADE80")
    static let stateAgainTint = Color(hex: "#F7A58C").opacity(0.10)
    static let stateHardTint  = Color(hex: "#E8A867").opacity(0.10)
    static let stateEasyTint  = Color(hex: "#4ADE80").opacity(0.12)

    static let deckPaletteHex: [String] = [
        "#D4AF37", "#B5A9F3", "#F2B8A6", "#9AD3B6",
        "#7FB8D4", "#E8A87C", "#B8D47F", "#D4A0C0"
    ]
}
