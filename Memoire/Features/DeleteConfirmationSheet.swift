import SwiftUI

enum DeleteTarget {
    case card(name: String)
    case deck(name: String, cardCount: Int)

    var title: String {
        switch self {
        case .card: "Supprimer cette carte ?"
        case .deck: "Supprimer ce paquet ?"
        }
    }

    var message: String {
        switch self {
        case .card(let name):
            "« \(name) » sera supprimée de façon irréversible."
        case .deck(let name, 0):
            "« \(name) » sera supprimé de façon irréversible."
        case .deck(let name, 1):
            "« \(name) » et sa carte seront supprimés de façon irréversible."
        case .deck(let name, let count):
            "« \(name) » et ses \(count) cartes seront supprimés de façon irréversible."
        }
    }

    var confirmAccessibilityLabel: String {
        switch self {
        case .card(let name):
            "Supprimer définitivement \(name)"
        case .deck(let name, 0):
            "Supprimer définitivement \(name)"
        case .deck(let name, 1):
            "Supprimer définitivement \(name) et sa carte"
        case .deck(let name, let count):
            "Supprimer définitivement \(name) et ses \(count) cartes"
        }
    }
}

struct DeleteConfirmationSheet: View {
    let target: DeleteTarget
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Color.red)
                .padding(.top, 8)

            Text(target.title)
                .font(.serif(22, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text(target.message)
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
                .accessibilityLabel(target.confirmAccessibilityLabel)
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
