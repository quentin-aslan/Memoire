import OSLog
import SwiftData
import SwiftUI

struct DecksScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.appPreferences) private var prefs
    @Query(sort: \Deck.position) private var allDecks: [Deck]
    @Query private var allReviews: [Review]

    @State private var editingDeck: DeckDraft?
    @State private var deckToDelete: Deck?
    @State private var deckSession: ReviewSession?
    @State private var navPath = NavigationPath()
    @State private var pendingNewDeck: Deck?
    @State private var autoOpenEditorForDeckID: UUID?

    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "DecksScreen")

    private var visibleDecks: [Deck] {
        allDecks.filter { !$0.isDeleted }
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
            .navigationBarTitleDisplayMode(.large)
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
            .fullScreenCover(item: $deckSession) { session in
                ReviewScreen(session: session)
            }
            .sheet(item: $deckToDelete) { deck in
                DeleteConfirmationSheet(
                    target: .deck(name: deck.name, cardCount: deck.cards.filter { !$0.isDeleted }.count),
                    onConfirm: {
                        softDelete(deck)
                        deckToDelete = nil
                    },
                    onCancel: { deckToDelete = nil }
                )
                .presentationDetents([.medium])
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
                        Button(role: .destructive) {
                            deckToDelete = deck
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

    private func launchSession(for deck: Deck) {
        let queue = DailyQueue.build(
            allCards: deck.cards,
            allReviews: allReviews,
            dailyNewCards: prefs.dailyNewCards
        )
        guard !queue.isEmpty else { return }
        deckSession = ReviewSession(cards: queue)
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
        let dueCount = deck.cards.filter { !$0.isDeleted && ($0.nextReviewDate ?? .distantFuture) <= .now }.count
        let totalCount = deck.cards.filter { !$0.isDeleted }.count
        let deckColor = Color(hex: deck.color ?? Color.goldHex)

        return HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(deckColor)
                .frame(width: 4)
                .frame(maxHeight: .infinity)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(deck.name)
                        .font(.serif(19, weight: .medium))
                        .foregroundStyle(Color.textPrimary)

                    HStack(spacing: 6) {
                        if dueCount > 0 {
                            Circle().fill(Color.gold).frame(width: 6, height: 6)
                            Text("\(dueCount) dues")
                                .font(.sans(12, weight: .semibold))
                                .foregroundStyle(Color.gold)
                            Text("·")
                                .foregroundStyle(Color.textTertiary)
                        }
                        Text("\(totalCount) cartes")
                            .font(.sans(12))
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Spacer()

                if dueCount > 0 {
                    Button {
                        launchSession(for: deck)
                    } label: {
                        Text("Réviser")
                            .font(.sans(12, weight: .semibold))
                            .foregroundStyle(Color.bgPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gold, in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 12)
            .padding(.leading, 14)
            .padding(.trailing, 12)
        }
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
    // via the isDeleted flag must cascade manually so children stop surfacing in the UI.
    private func softDelete(_ deck: Deck) {
        let now = Date.now
        let pendingDelete = SyncStatus.pendingDelete.rawValue
        for card in deck.cards where !card.isDeleted {
            card.isDeleted = true
            card.deletedAt = now
            card.syncVersion += 1
            card.syncStatus = pendingDelete
        }
        deck.isDeleted = true
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
