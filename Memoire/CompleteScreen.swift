import SwiftUI

// CompleteScreen v4 — single hero number + a sentence drawn from one of three
// registers (descriptive, interpretive, gentle pedagogy). Brief §2.2/§4.2.
// Tirage pondéré 3/8 R1, 3/8 R2, 2/8 R3 with no-repeat across consecutive
// sessions (persisted via AppPreferences.lastShownInsightID).

struct CompleteScreen: View {
    let uniqueCount: Int
    let onDone: () -> Void

    @Environment(\.appPreferences) private var prefs
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animateIn: Bool = false
    @State private var insight: CompletionInsight?

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            // Close button — top right, 44×44 tap target
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDone) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.trailing, 8)
                    .padding(.top, 4)
                }
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()

                // Hero number
                Text("\(uniqueCount)")
                    .font(.serif(96, weight: .light))
                    .foregroundStyle(Color.gold)
                    .monospacedDigit()
                    .scaleEffect(animateIn || reduceMotion ? 1.0 : 0.95)
                    .opacity(animateIn ? 1 : 0)

                // Underline — 56×2pt, 6pt below baseline
                Rectangle()
                    .fill(Color.gold)
                    .frame(width: animateIn || reduceMotion ? 56 : 0, height: 2)
                    .padding(.top, 6)

                // Sentence
                Text(insight?.text ?? "")
                    .font(.serif(20))
                    .foregroundStyle(Color.textReading.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 300)
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    .opacity(animateIn ? 1 : 0)

                Spacer()

                // Outline button "Terminer"
                Button(action: onDone) {
                    Text("Terminer")
                        .font(.sans(17, weight: .medium))
                        .foregroundStyle(Color.gold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.gold, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(animateIn ? 1 : 0)
            }
        }
        .onAppear { performAppear() }
    }

    private func performAppear() {
        // Pick the insight once, persist its ID so we don't repeat next session.
        if insight == nil {
            let pick = CompletionInsight.pick(
                uniqueCount: uniqueCount,
                lastShownID: prefs.lastShownInsightID,
                now: .now
            )
            insight = pick
            prefs.lastShownInsightID = pick.id
        }

        if reduceMotion {
            animateIn = true
        } else {
            withAnimation(.easeOut(duration: 0.4)) { animateIn = true }
        }
    }
}

// MARK: - Completion insight pool — 18 sentences across 3 registers (brief §4.2)
//
// Registers:
//   R1 descriptive — factual, sober. The default register.
//   R2 interpretive — Whoop-style "your memory tightens" framing.
//   R3 gentle pedagogy — explains the underlying mechanism without naming FSRS.
//                        Tirage rarer (2/8). Has the highest risk of feeling
//                        preachy — flagged for kill if testers report ≥3/30
//                        as "scolaire" (brief §5.3).
//
// Selection rules:
//   - uniqueCount < 3 → R1 only (the data-richer registers don't make sense
//                                 on a 1-2 card session).
//   - uniqueCount ≥ 3 → weighted draw 3/8 R1, 3/8 R2, 2/8 R3.
//   - Never repeat the same sentence in consecutive sessions
//     (AppPreferences.lastShownInsightID).

struct CompletionInsight {
    let id: String
    let text: String
}

extension CompletionInsight {
    static func pick(uniqueCount: Int, lastShownID: String?, now: Date) -> CompletionInsight {
        let pool = candidates(uniqueCount: uniqueCount, now: now)
        let filtered = pool.filter { $0.id != lastShownID }
        return (filtered.isEmpty ? pool : filtered).randomElement() ?? pool[0]
    }

    private static func candidates(uniqueCount n: Int, now: Date) -> [CompletionInsight] {
        let r1 = registerOne(n: n, now: now)
        guard n >= 3 else { return r1 }
        // Weighted draw via repetition: R1 ×3, R2 ×3, R3 ×2 → 8 slots over 18
        // distinct sentences — rerolling within each register on duplicates.
        return r1 + r1 + r1
            + registerTwo(n: n) + registerTwo(n: n) + registerTwo(n: n)
            + registerThree() + registerThree()
    }

    // R1 — descriptive
    private static func registerOne(n: Int, now: Date) -> [CompletionInsight] {
        let cards = n == 1 ? "carte" : "cartes"
        let isMorning = Calendar.current.component(.hour, from: now) < 14
        return [
            CompletionInsight(id: "r1.consolidated",   text: "\(n) \(cards) consolidées aujourd'hui."),
            CompletionInsight(id: "r1.session_done",   text: "Session terminée. \(n) \(cards) revues."),
            CompletionInsight(id: "r1.behind_you",     text: "\(n) \(cards) derrière toi."),
            CompletionInsight(id: isMorning ? "r1.morning" : "r1.evening",
                              text: isMorning
                                ? "Tu as bouclé \(n) \(cards) ce matin."
                                : "Tu as bouclé \(n) \(cards) ce soir."),
            CompletionInsight(id: "r1.close_book",     text: "\(n) \(cards) — tu peux refermer.")
        ]
    }

    // R2 — interpretive (drops sentences that need cross-session deltas; we
    // ship the 4 that work with just `n`).
    private static func registerTwo(n: Int) -> [CompletionInsight] {
        let cards = n == 1 ? "carte" : "cartes"
        return [
            CompletionInsight(id: "r2.gained_solid",   text: "\(n) \(cards) ont gagné en solidité aujourd'hui."),
            CompletionInsight(id: "r2.holds_better",   text: "Ton paquet tient un peu mieux qu'hier."),
            CompletionInsight(id: "r2.come_back_later", text: "Ces \(n) \(cards) reviendront plus tard cette fois."),
            CompletionInsight(id: "r2.extends_gap",    text: "Mémoire prolonge l'écart sur \(n) \(cards)."),
            CompletionInsight(id: "r2.responds_well",  text: "Sur ces \(n) \(cards), ta mémoire répond bien.")
        ]
    }

    // R3 — gentle pedagogy. No substitutions; pure copy.
    private static func registerThree() -> [CompletionInsight] {
        [
            CompletionInsight(id: "r3.brings_back",     text: "Mémoire ramènera ces cartes pile avant que tu ne les oublies."),
            CompletionInsight(id: "r3.no_force",        text: "Tu n'as rien à mémoriser de force — Mémoire programme le retour."),
            CompletionInsight(id: "r3.invisible_work", text: "Le travail invisible se passe entre les sessions."),
            CompletionInsight(id: "r3.spacing_grows",  text: "Plus tu reviens, plus l'espacement grandit."),
            CompletionInsight(id: "r3.gap_makes_memory", text: "C'est l'écart entre les révisions qui fait la mémoire."),
            CompletionInsight(id: "r3.holds_longer",   text: "Ce que tu retrouves aujourd'hui tiendra plus longtemps.")
        ]
    }
}

#Preview {
    CompleteScreen(uniqueCount: 12, onDone: {})
}
