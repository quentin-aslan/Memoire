import OSLog
import SwiftData
import SwiftUI

struct DeckDetailScreen: View {
    @Environment(\.modelContext) private var context
    let deck: Deck
    let autoOpenCardEditor: Bool
    let onAutoOpenConsumed: (() -> Void)?

    @State private var editingCard: CardDraft?

    init(deck: Deck, autoOpenCardEditor: Bool = false, onAutoOpenConsumed: (() -> Void)? = nil) {
        self.deck = deck
        self.autoOpenCardEditor = autoOpenCardEditor
        self.onAutoOpenConsumed = onAutoOpenConsumed
    }
    @State private var cardToDelete: Card?

    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "DeckDetailScreen")

    private var sortedCards: [Card] {
        deck.cards
            .filter { !$0.isDeleted }
            .sorted { $0.createdAt < $1.createdAt }
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
        .sheet(item: $cardToDelete) { card in
            DeleteConfirmationSheet(
                target: .card(name: card.front),
                onConfirm: {
                    softDelete(card)
                    cardToDelete = nil
                },
                onCancel: { cardToDelete = nil }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(true)
        }
        .task {
            guard autoOpenCardEditor else { return }
            onAutoOpenConsumed?()
            do {
                try await Task.sleep(for: .milliseconds(400))
            } catch {
                return
            }
            editingCard = CardDraft(deckID: deck.id)
        }
    }

    private var listContent: some View {
        List {
            Section {
                ForEach(sortedCards) { card in
                    NavigationLink(value: card) {
                        cardRow(card)
                    }
                    .listRowBackground(Color.bgCard)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            cardToDelete = card
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

    private func cardRow(_ card: Card) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.front)
                .font(.serif(17, weight: .regular))
                .foregroundStyle(Color.textReading)
                .multilineTextAlignment(.leading)
                .lineLimit(2)

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

    private func statusColor(for card: Card) -> Color {
        guard let next = card.nextReviewDate else { return .textTertiary }
        return next <= .now ? .gold : Color.white.opacity(0.2)
    }

    private func statusLabel(for card: Card) -> String {
        guard let next = card.nextReviewDate else { return "NOUVELLE" }
        if next <= .now { return "À RÉVISER" }
        return "PRÉVUE \(Self.dateFormatter.string(from: next).uppercased())"
    }

    private func softDelete(_ card: Card) {
        card.isDeleted = true
        card.deletedAt = .now
        card.syncVersion += 1
        card.syncStatus = SyncStatus.pendingDelete.rawValue
        do {
            try context.save()
        } catch {
            Self.logger.error("Failed to soft-delete card: \(error.localizedDescription)")
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "d MMM"
        return f
    }()
}
