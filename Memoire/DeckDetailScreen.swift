import OSLog
import SwiftData
import SwiftUI

struct DeckDetailScreen: View {
    @Environment(\.modelContext) private var context
    let deck: Deck
    let autoOpenCardEditor: Bool
    let onAutoOpenConsumed: (() -> Void)?

    @State private var editingCard: CardDraft?
    @State private var deleteRequest: DeleteRequest?
    @State private var showStatsSheet: Bool = false
    @State private var activeSession: ReviewSession?

    init(deck: Deck, autoOpenCardEditor: Bool = false, onAutoOpenConsumed: (() -> Void)? = nil) {
        self.deck = deck
        self.autoOpenCardEditor = autoOpenCardEditor
        self.onAutoOpenConsumed = onAutoOpenConsumed
    }

    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "DeckDetailScreen")

    private var sortedCards: [Card] {
        deck.cards
            .filter { !$0.isSoftDeleted }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var dueCardsForReview: [Card] {
        // Same priority as DailyQueue but scoped to this deck only — due first,
        // then any new cards in the deck (capped to dailyNewCards is a global
        // concern, but at the deck level we trust the user explicitly chose
        // this deck and just show what's actionable).
        let active = sortedCards
        let dueNonNew = active.filter { card in
            guard card.fsrsReps > 0, let next = card.nextReviewDate else { return false }
            return next <= .now
        }
        let newCards = active.filter { $0.fsrsReps == 0 }
        return dueNonNew + newCards
    }

    var body: some View {
        Group {
            if sortedCards.isEmpty {
                emptyStateContent
            } else {
                listContent
            }
        }
        .background(Color.bgPrimary)
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editingCard = CardDraft(deckID: deck.id)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editingCard) { draft in
            CardEditorSheet(initialDraft: draft)
        }
        .sheet(item: $deleteRequest) { request in
            DeleteConfirmationSheet(
                target: request.target,
                onConfirm: {
                    request.confirm()
                    deleteRequest = nil
                },
                onCancel: { deleteRequest = nil }
            )
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $showStatsSheet) {
            DeckStatsSheet(deck: deck)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $activeSession) { session in
            ReviewScreen(session: session)
        }
        .task {
            guard autoOpenCardEditor else { return }
            onAutoOpenConsumed?()
            do {
                try await Task.sleep(for: .milliseconds(100))
            } catch {
                return
            }
            editingCard = CardDraft(deckID: deck.id)
        }
    }

    private var listContent: some View {
        List {
            Section {
                heroCard
                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 8, trailing: 20))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                if !dueCardsForReview.isEmpty {
                    reviseCTA
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 16, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                ForEach(sortedCards) { card in
                    NavigationLink(value: card) {
                        cardRow(card)
                    }
                    .listRowBackground(Color.bgCard)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            deleteRequest = DeleteRequest(
                                target: .card(name: card.front),
                                confirm: { softDelete(card) }
                            )
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                        .tint(.red)

                        Button {
                            editingCard = CardDraft.edit(card)
                        } label: {
                            Label("Modifier", systemImage: "pencil")
                        }
                        .tint(.gold)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }

    // MARK: - Hero card with composition bar

    private var heroCard: some View {
        // Single tally pass instead of three (one per band).
        let comp = deck.composition
        return VStack(alignment: .leading, spacing: 14) {
            Text(headlineText)
                .font(.serif(22))
                .foregroundStyle(Color.textReading)
                .monospacedDigit()
                .lineSpacing(2)

            CompositionBar(solid: comp.solid, consolidating: comp.consolidating, toBack: comp.toBack)

            VStack(spacing: 8) {
                legendLine(color: CompositionBar.legendColors.solid, label: "Stables", count: comp.solid)
                legendLine(color: CompositionBar.legendColors.consolidating, label: "En consolidation", count: comp.consolidating)
                legendLine(color: CompositionBar.legendColors.toBack, label: "À ramener", count: comp.toBack)
            }
            .padding(.top, 2)

            Rectangle().fill(Color.bgElevated.opacity(0.6)).frame(height: 0.5)

            VStack(alignment: .leading, spacing: 4) {
                Text("À réviser cette semaine · \(deck.dueThisWeek())")
                    .font(.sans(14))
                    .foregroundStyle(Color.textSecondary)

                Text("Solidité moyenne · \(meanStabilityLabel)")
                    .font(.sans(14))
                    .foregroundStyle(Color.textSecondary)
            }

            Rectangle().fill(Color.bgElevated.opacity(0.6)).frame(height: 0.5)

            Button { showStatsSheet = true } label: {
                HStack {
                    Text("Voir le détail")
                        .font(.sans(15, weight: .medium))
                        .foregroundStyle(Color.textReading)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(height: 28)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.bgCard, in: .rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.24), radius: 14, y: 2)
    }

    private func legendLine(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.sans(12))
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text("\(count)")
                .font(.sans(12, weight: .medium))
                .foregroundStyle(Color.textReading)
                .monospacedDigit()
        }
    }

    private var reviseCTA: some View {
        Button {
            activeSession = ReviewSession(cards: dueCardsForReview)
        } label: {
            Text("Réviser maintenant")
        }
        .buttonStyle(.primary(verticalPadding: 18))
    }

    // MARK: - Headline + mean stability copy

    private var headlineText: String {
        let total = deck.totalActiveCards
        let solid = deck.solidCount

        if total == 0 { return String(localized: "Ce paquet est vide. Ajoute ta première carte.") }
        if solid == 0 { return String(localized: "Aucune carte encore consolidée. \(total) cartes en attente.") }
        if solid == total { return String(localized: "Tout ce paquet est consolidé.") }
        return String(localized: "\(solid) / \(total) cartes consolidées")
    }

    private var meanStabilityLabel: String {
        guard let mean = deck.meanStability else { return "—" }
        return formatDurationDays(max(1, Int(mean.rounded())))
    }

    // MARK: - Empty state

    private var emptyStateContent: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.text")
                .font(.system(size: 44))
                .foregroundStyle(Color.textTertiary)

            Text("Aucune carte pour l'instant.")
                .font(.serif(20, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            Button {
                editingCard = CardDraft(deckID: deck.id)
            } label: {
                Text("+ Ajouter une carte")
                    .font(.uiButton)
                    .foregroundStyle(Color.bgPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.goldLight, .gold],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: .rect(cornerRadius: 12)
                    )
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Card row (preserved from previous version)

    private func cardRow(_ card: Card) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text(card.front)
                    .font(.serif(17, weight: .regular))
                    .foregroundStyle(Color.textReading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if card.hasBackDrawing {
                    drawingBadge
                }
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor(for: card))
                    .frame(width: 6, height: 6)

                Text(statusLabel(for: card))
                    .font(.sans(11, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }

    private var drawingBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "pencil.tip")
                .font(.system(size: 10, weight: .semibold))
            Text("Dessin")
                .font(.sans(10, weight: .semibold))
                .tracking(0.4)
        }
        .foregroundStyle(Color.gold)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.goldTint, in: .capsule)
        .accessibilityLabel("Réponse dessinée")
    }

    private func statusColor(for card: Card) -> Color {
        guard let next = card.nextReviewDate else { return .textTertiary }
        return next <= .now ? .gold : .textTertiary
    }

    private func statusLabel(for card: Card) -> String {
        guard let next = card.nextReviewDate else { return String(localized: "NOUVELLE") }
        if next <= .now { return String(localized: "À RÉVISER") }
        let dateStr = next.formatted(.dateTime.day().month(.abbreviated)).uppercased()
        return String(localized: "PRÉVUE \(dateStr)")
    }

    private func softDelete(_ card: Card) {
        card.isSoftDeleted = true
        card.deletedAt = .now
        card.syncVersion += 1
        card.syncStatus = SyncStatus.pendingDelete.rawValue
        do {
            try context.save()
        } catch {
            Self.logger.error("Failed to soft-delete card: \(error.localizedDescription)")
        }
    }

}
