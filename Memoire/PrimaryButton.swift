import SwiftUI

// Shared gold-gradient CTA style used across the app (onboarding, empty states,
// complete screen, settings...). Applies press feedback that standalone views
// with custom backgrounds don't get for free.
struct PrimaryButtonStyle: ButtonStyle {
    var verticalPadding: CGFloat = 16
    var cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.uiButton)
            .foregroundStyle(Color.bgPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .background(
                LinearGradient(
                    colors: [.goldLight, .gold],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: .rect(cornerRadius: cornerRadius)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }

    static func primary(verticalPadding: CGFloat) -> PrimaryButtonStyle {
        PrimaryButtonStyle(verticalPadding: verticalPadding)
    }
}
