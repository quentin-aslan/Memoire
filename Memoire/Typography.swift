import SwiftUI

extension Font {
    static func serif(_ size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func sans(_ size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

extension Font {
    static let cardQuestion = Font.serif(34, weight: .medium)
    static let cardAnswer   = Font.serif(20, weight: .regular)

    static let uiLargeTitle = Font.sans(34, weight: .bold)
    static let uiTitle      = Font.sans(22, weight: .semibold)
    static let uiBody       = Font.sans(17, weight: .regular)
    static let uiCallout    = Font.sans(15, weight: .regular)
    static let uiButton     = Font.sans(15, weight: .semibold)
    static let uiCaption    = Font.sans(11, weight: .semibold)
}
