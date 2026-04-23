import OSLog
import SwiftData
import SwiftUI

struct DecksScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.deckCreation) private var deckCreation
    @Query(sort: \Deck.position) private var allDecks: [Deck]

    @State private var editingDeck: DeckDraft?
    @State private var deleteRequest: DeleteRequest?
    @State private var navPath = NavigationPath()
    @State private var pendingNewDeck: Deck?
    @State private var autoOpenEditorForDeckID: UUID?
    @State private var quickCardEditor: CardDraft?

    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "DecksScreen")

    private var visibleDecks: [Deck] {
        allDecks.filter { !$0.isSoftDeleted }
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            Group {
                if visibleDecks.isEmpty {
                    emptyStateContent
                } else {
                    listContent
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle("Paquets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingDeck = DeckDraft()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                if !visibleDecks.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                }
            }
            .sheet(item: $editingDeck, onDismiss: handleDeckEditorDismiss) { draft in
                DeckEditorSheet(initialDraft: draft, onCreated: { deck in
                    pendingNewDeck = deck
                })
            }
            .sheet(item: $quickCardEditor) { draft in
                CardEditorSheet(initialDraft: draft)
            }
            .onAppear {
                guard let deck = deckCreation.createdDeck else { return }
                deckCreation.createdDeck = nil
                quickCardEditor = CardDraft(deckID: deck.id)
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
            .navigationDestination(for: Deck.self) { deck in
                DeckDetailScreen(
                    deck: deck,
                    autoOpenCardEditor: autoOpenEditorForDeckID == deck.id,
                    onAutoOpenConsumed: { autoOpenEditorForDeckID = nil }
                )
            }
            .navigationDestination(for: Card.self) { card in
                CardDetailScreen(card: card)
            }
        }
    }

    private func handleDeckEditorDismiss() {
        guard let deck = pendingNewDeck else { return }
        pendingNewDeck = nil
        autoOpenEditorForDeckID = deck.id
        navPath.append(deck)
    }

    private var listContent: some View {
        List {
            Section {
                ForEach(visibleDecks) { deck in
                    NavigationLink(value: deck) {
                        deckRowContent(deck)
                    }
                    .listRowBackground(Color.bgCard)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            deleteRequest = DeleteRequest(
                                target: .deck(
                                    name: deck.name,
                                    cardCount: deck.cards.filter { !$0.isSoftDeleted }.count
                                ),
                                confirm: { softDelete(deck) }
                            )
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                        .tint(.red)

                        Button {
                            editingDeck = DeckDraft.edit(deck)
                        } label: {
                            Label("Modifier", systemImage: "pencil")
                        }
                        .tint(.gold)
                    }
                }
                .onMove(perform: moveDecks)
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }

    private var emptyStateContent: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "rectangle.stack")
                .font(.system(size: 44))
                .foregroundStyle(Color.textTertiary)

            Text("Aucun paquet pour l'instant.")
                .font(.serif(20, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            Text("Créez votre premier paquet pour commencer.")
                .font(.serif(15))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                editingDeck = DeckDraft()
            } label: {
                Text("+ Créer un paquet")
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

    private func deckRowContent(_ deck: Deck) -> some View {
        let dueCount = deck.cards.filter { !$0.isSoftDeleted && ($0.nextReviewDate ?? .distantFuture) <= .now }.count
        let totalCount = deck.cards.filter { !$0.isSoftDeleted }.count
        let deckColor = Color(hex: deck.color ?? Color.goldHex)

        return HStack(spacing: 14) {
            Capsule()
                .fill(deckColor)
                .frame(width: 3, height: 36)
                .shadow(color: deckColor.opacity(0.7), radius: 8, x: 0, y: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.serif(17, weight: .medium))
                    .foregroundStyle(Color.textPrimary)

                Text("\(totalCount) carte\(totalCount == 1 ? "" : "s")")
                    .font(.sans(13))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            if dueCount > 0 {
                Text("\(dueCount)")
                    .font(.sans(14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.bgElevated, in: .circle)
            } else {
                Text("à jour")
                    .font(.sans(12))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.vertical, 14)
        .padding(.leading, 14)
        .padding(.trailing, 12)
    }

    private func moveDecks(from source: IndexSet, to destination: Int) {
        var reordered = visibleDecks
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, deck) in reordered.enumerated() where deck.position != index {
            deck.position = index
            deck.syncVersion += 1
            deck.syncStatus = SyncStatus.pendingUpdate.rawValue
        }
        do {
            try context.save()
        } catch {
            Self.logger.error("Failed to reorder decks: \(error.localizedDescription)")
        }
    }

    // @Relationship(deleteRule: .cascade) fires only on context.delete(); soft-delete
    // via the isSoftDeleted flag must cascade manually so children stop surfacing in the UI.
    private func softDelete(_ deck: Deck) {
        let now = Date.now
        let pendingDelete = SyncStatus.pendingDelete.rawValue
        for card in deck.cards where !card.isSoftDeleted {
            card.isSoftDeleted = true
            card.deletedAt = now
            card.syncVersion += 1
            card.syncStatus = pendingDelete
        }
        deck.isSoftDeleted = true
        deck.deletedAt = now
        deck.syncVersion += 1
        deck.syncStatus = pendingDelete
        do {
            try context.save()
        } catch {
            Self.logger.error("Failed to soft-delete deck cascade: \(error.localizedDescription)")
        }
    }
}
