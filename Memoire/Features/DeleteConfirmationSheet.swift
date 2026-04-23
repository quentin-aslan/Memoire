import SwiftUI

struct DeleteConfirmationSheet: View {
    let itemName: String
    let cardCount: Int?
    let title: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private var messageText: String {
        guard let count = cardCount else {
            return "« \(itemName) » sera supprimée de façon irréversible."
        }
        switch count {
        case 0:
            return "« \(itemName) » sera supprimé de façon irréversible."
        case 1:
            return "« \(itemName) » et sa carte seront supprimés de façon irréversible."
        default:
            return "« \(itemName) » et ses \(count) cartes seront supprimés de façon irréversible."
        }
    }

    private var confirmAccessibilityLabel: String {
        guard let count = cardCount, count > 0 else {
            return "Supprimer définitivement \(itemName)"
        }
        if count == 1 {
            return "Supprimer définitivement \(itemName) et sa carte"
        }
        return "Supprimer définitivement \(itemName) et ses \(count) cartes"
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Color.red)
                .padding(.top, 8)

            Text(title)
                .font(.serif(22, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text(messageText)
                .font(.serif(17))
                .foregroundStyle(Color.textReading)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Annuler")
                        .font(.uiButton)
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.bgCard, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button(action: onConfirm) {
                    Text("Supprimer")
                        .font(.uiButton)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red, in: .rect(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isDestructive)
                .accessibilityLabel(confirmAccessibilityLabel)
                .accessibilityHint("Action irréversible")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary)
    }
}
