import SwiftUI

// Shared pattern for the two ⓘ half-sheets (Solidité + Fraîcheur — brief §2.5).
// One component, two factory constructors with the locked editorial copy.
//
// Doctrine A: these are the *only* pedagogical surfaces in the app besides
// onboarding écran 4. Adding a third should require an explicit decision —
// every additional pedagogical surface dilutes the "FSRS is invisible" promise.

struct EditorialSheet: View {
    let title: String
    let paragraphs: [String]
    let coda: String
    let footnoteLabel: String
    let footnoteExpanded: String

    @Environment(\.dismiss) private var dismiss
    @State private var footnoteOpen: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(paragraphs.indices, id: \.self) { i in
                            Text(paragraphs[i])
                                .font(.serif(17))
                                .foregroundStyle(Color.textReading.opacity(0.95))
                                .lineSpacing(3)
                        }

                        Text(coda)
                            .font(.serif(17))
                            .italic()
                            .foregroundStyle(Color.gold.opacity(0.8))
                            .padding(.top, 6)

                        footnote
                            .padding(.top, 12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text(title)
                .font(.serif(22, weight: .semibold))
                .foregroundStyle(Color.textReading)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.leading, 24)
        .padding(.trailing, 4)
        .padding(.top, 8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.bgElevated).frame(height: 0.5)
        }
    }

    private var footnote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { footnoteOpen.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: footnoteOpen ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                    Text(footnoteLabel)
                        .font(.sans(14))
                }
                .foregroundStyle(Color.textSecondary)
            }
            .buttonStyle(.plain)

            if footnoteOpen {
                Text(footnoteExpanded)
                    .font(.sans(14))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.leading, 18)
                    .lineSpacing(2)
            }
        }
        .padding(.top, 12)
    }
}

// MARK: - Factory functions — copy verbatim from brief §2.5

extension EditorialSheet {
    static func solidite() -> EditorialSheet {
        EditorialSheet(
            title: "Solidité",
            paragraphs: [
                "La solidité, c'est combien de temps un souvenir tient avant qu'on doive le revoir.",
                "Quand tu retrouves une carte sans trop d'effort, sa solidité augmente — Mémoire l'espace alors davantage. Quand tu hésites, elle redescend, et la carte revient plus tôt."
            ],
            coda: "Tu n'as rien à régler. Mémoire s'en occupe.",
            footnoteLabel: "En anglais : Stability",
            footnoteExpanded: "En anglais, on parle de « Stability » — c'est la même chose."
        )
    }

    static func fraicheur() -> EditorialSheet {
        EditorialSheet(
            title: "Fraîcheur",
            paragraphs: [
                "La fraîcheur, c'est la probabilité que tu te souviennes encore d'une carte aujourd'hui.",
                "Plus le temps passe sans révision, plus elle baisse. Quand elle descend trop, Mémoire ramène la carte avant que tu ne l'oublies vraiment.",
                "On ne te montre pas un pourcentage qui descend en direct — ce serait du bruit. Mémoire s'en occupe en silence."
            ],
            coda: "Tu fais le rappel. Mémoire fait le calcul.",
            footnoteLabel: "En anglais : Retrievability",
            footnoteExpanded: "En anglais, on parle de « Retrievability » — c'est la même chose."
        )
    }
}
