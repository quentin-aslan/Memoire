// Single entry point for all Liquid Glass surfaces — see ADR-0002 and the
// Glass convention in CLAUDE.md for the chrome-only doctrine and fallback rules.

import SwiftUI

extension View {
    func memoireSurface<S: Shape>(
        in shape: S = .rect(cornerRadius: 16),
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        modifier(MemoireSurface(shape: shape, tint: tint, interactive: interactive))
    }
}

private struct MemoireSurface<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color?
    let interactive: Bool

    @Environment(\.appPreferences) private var prefs
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func body(content: Content) -> some View {
        let useSolid = prefs.calmMode || reduceTransparency

        if #available(iOS 26.0, *), !useSolid {
            content.memoireGlass(
                tint: tint,
                interactive: interactive && !reduceMotion,
                in: shape
            )
        } else {
            content.background(Color.surfaceRaised, in: shape)
        }
    }
}

@available(iOS 26.0, *)
private extension View {
    func memoireGlass<S: Shape>(tint: Color?, interactive: Bool, in shape: S) -> some View {
        var glass: Glass = .regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return self.glassEffect(glass, in: shape)
    }
}
