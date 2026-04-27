import SwiftData
import SwiftUI

struct ReviewScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appPreferences) private var prefs

    @Bindable var session: ReviewSession
    @State private var showPermissionToFailToast: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()

            if session.isComplete {
                CompleteScreen(
                    uniqueCount: session.uniqueReviewedCount,
                    onDone: { dismiss() }
                )
            } else if let card = session.currentCard {
                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    cardView(card: card)
                        .padding(.horizontal, 24)
                    Spacer()
                    bottomBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                }
                .onTapGesture {
                    if !session.flipped { flipCard() }
                }
            } else {
                Text("Aucune carte à réviser")
                    .font(.serif(22, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
            }

            // Permission-to-fail toast — top safe area + 12pt, auto-dismiss 4s
            ReviewToast(visible: $showPermissionToFailToast)
                .padding(.top, 12)
        }
        .animation(.easeInOut(duration: 0.25), value: session.isComplete)
        .sensoryFeedback(.selection, trigger: session.flipped)
        .sensoryFeedback(.impact(weight: .light), trigger: session.currentIndex)
        .sensoryFeedback(.success, trigger: session.isComplete)
        .onChange(of: session.isComplete) { _, isComplete in
            guard isComplete else { return }
            WidgetSnapshotWriter.refresh(context: context, prefs: prefs)
        }
        .onChange(of: session.completedRatings.count) { _, _ in
            evaluateToastTrigger()
        }
    }

    // Permission-to-fail toast — shown once when the user has accumulated 3
    // "À revoir" across their lifetime of using the app. Triggers between
    // cards (after the rating tap, before the next card flips into view) so
    // it doesn't sit on top of an active card.
    private func evaluateToastTrigger() {
        guard session.completedRatings.last == .again,
              prefs.cumulativeAgainCount >= 3,
              !prefs.permissionToFailToastShown
        else { return }
        prefs.permissionToFailToastShown = true
        withAnimation(.easeOut(duration: 0.32)) {
            showPermissionToFailToast = true
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Color.bgCard, in: .circle)
            }

            Spacer()

            Text("\(session.uniqueReviewedCount) / \(session.originalCount)")
                .font(.sans(14, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .monospacedDigit()

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .overlay(alignment: .bottom) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(Color.gold)
                        .frame(width: geo.size.width * session.progress)
                        .animation(.easeInOut, value: session.progress)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 20)
            .offset(y: 18)
        }
    }

    @ViewBuilder
    private func cardView(card: Card) -> some View {
        if reduceMotion {
            cardFace(card: card, side: session.flipped ? .back : .front)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: session.flipped)
        } else {
            ZStack {
                cardFace(card: card, side: .front)
                    .opacity(session.flipped ? 0 : 1)

                cardFace(card: card, side: .back)
                    .opacity(session.flipped ? 1 : 0)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
            .rotation3DEffect(
                .degrees(session.flipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .animation(.spring(response: 0.55, dampingFraction: 0.72), value: session.flipped)
        }
    }

    private enum CardSide { case front, back }

    @ViewBuilder
    private func cardFace(card: Card, side: CardSide) -> some View {
        VStack(spacing: 22) {
            Spacer(minLength: 0)

            cardFaceContent(card: card, side: side)

            Spacer(minLength: 0)

            if side == .front {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.gold)
                        .frame(width: 6, height: 6)
                    Text("APPUYEZ POUR RÉVÉLER")
                        .font(.sans(11, weight: .semibold))
                        .tracking(1.6)
                        .foregroundStyle(Color.gold)
                }
                .padding(.bottom, 22)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
        .background(Color.surfaceElevated, in: .rect(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.goldSubtle, lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func cardFaceContent(card: Card, side: CardSide) -> some View {
        if side == .back, let drawingData = card.backDrawing, !drawingData.isEmpty {
            DrawingDisplay(data: drawingData)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        } else {
            Text(side == .front ? card.front : card.back)
                .font(.serif(28, weight: .regular))
                .foregroundStyle(Color.textReading)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if session.flipped {
            ratingButtonsGroup
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            Color.clear.frame(height: 64)
        }
    }

    @ViewBuilder
    private var ratingButtonsGroup: some View {
        if #available(iOS 26.0, *), !prefs.calmMode {
            GlassEffectContainer(spacing: 10) {
                ratingButtonsRow
            }
        } else {
            ratingButtonsRow
        }
    }

    private var ratingButtonsRow: some View {
        HStack(spacing: 10) {
            ForEach(Rating.allCases) { rating in
                ratingButton(rating)
            }
        }
    }

    private func ratingButton(_ rating: Rating) -> some View {
        Button {
            session.rate(rating, in: context)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: rating.glyph)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(rating.tint)
                Text(rating.label)
                    .font(.sans(14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 60, alignment: .center)
            .memoireSurface(
                in: .rect(cornerRadius: 14),
                tint: rating.tint
            )
        }
        .accessibilityLabel(rating.label)
        .accessibilityHint("Double-tap pour noter cette carte.")
    }

    private func flipCard() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            session.flip()
        }
    }
}
