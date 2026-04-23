import OSLog
import SwiftData
import SwiftUI

struct CardEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var draft: CardDraft
    @FocusState private var focusedField: Field?
    @State private var error: EditorError?
    @State private var savedCounter: Int = 0
    @State private var addedCount: Int = 0
    @State private var activeSegment: Segment = .question
    @State private var deckColor: String = Color.goldHex
    @State private var deckName: String = ""

    private let allowsQuickAdd: Bool
    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "CardEditor")

    enum Field: Hashable { case front, back }
    enum Segment: Hashable { case question, answer }

    init(initialDraft: CardDraft) {
        _draft = State(initialValue: initialDraft)
        self.allowsQuickAdd = !initialDraft.isEditing
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if allowsQuickAdd {
                    counterHeader
                        .padding(.top, 8)
                }

                segmentedPicker
                    .padding(.top, allowsQuickAdd ? 20 : 8)
                    .padding(.horizontal, 20)

                contentArea
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                progressBar
                    .padding(.top, 12)
                    .padding(.horizontal, 20)

                Spacer()
            }
            .background(Color.bgPrimary)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    navTitle
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if allowsQuickAdd {
                        Button("Terminer") {
                            if draft.isValid { save(keepOpen: false) } else { dismiss() }
                        }
                        .foregroundStyle(draft.isValid ? Color.gold : Color.textSecondary)
                    } else {
                        Button("Enregistrer") { save(keepOpen: false) }
                            .bold()
                            .disabled(!draft.isValid)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if allowsQuickAdd {
                    quickAddBar
                }
            }
            .alert(item: $error) { err in
                Alert(title: Text("Erreur"), message: Text(err.errorDescription ?? ""))
            }
            .sensoryFeedback(.success, trigger: savedCounter)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            await loadDeckInfo()
            try? await Task.sleep(for: .milliseconds(250))
            focusedField = .front
        }
    }

    private var navTitle: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: deckColor))
                .frame(width: 8, height: 8)
            Text(deckName.isEmpty ? "Nouvelle carte" : deckName)
                .font(.sans(15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
        }
    }

    private var counterHeader: some View {
        VStack(spacing: 4) {
            Text("\(addedCount)")
                .font(.serif(28, weight: .medium))
                .foregroundStyle(Color.gold)
                .contentTransition(.numericText(value: Double(addedCount)))
            Text("cartes ajoutées")
                .font(.sans(12))
                .foregroundStyle(Color.textSecondary)
        }
        .opacity(addedCount > 0 ? 1 : 0)
        .animation(.easeInOut, value: addedCount)
    }

    private var segmentedPicker: some View {
        HStack(spacing: 4) {
            segmentButton(.question, label: "Question", content: draft.trimmedFront)
            segmentButton(.answer, label: "Réponse", content: draft.trimmedBack)
        }
        .padding(4)
        .background(Color.bgCard, in: .rect(cornerRadius: 12))
    }

    private func segmentButton(_ segment: Segment, label: String, content: String) -> some View {
        let isActive = activeSegment == segment
        let isFilled = !content.isEmpty
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { activeSegment = segment }
            focusedField = segment == .question ? .front : .back
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(isFilled ? Color.stateEasy : Color.white.opacity(0.15))
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(.sans(14, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? Color.textPrimary : Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isActive ? Color.surfaceElevated : Color.clear,
                in: .rect(cornerRadius: 9)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: activeSegment)
    }

    private var contentArea: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )

            Group {
                if activeSegment == .question {
                    TextField(
                        "Qu'est-ce que vous voulez mémoriser ?",
                        text: $draft.front,
                        axis: .vertical
                    )
                    .focused($focusedField, equals: .front)
                } else {
                    TextField(
                        "La réponse à retenir…",
                        text: $draft.back,
                        axis: .vertical
                    )
                    .focused($focusedField, equals: .back)
                }
            }
            .font(.serif(18))
            .foregroundStyle(Color.textReading)
            .lineLimit(4...10)
            .padding(16)
        }
        .frame(minHeight: 160)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 2)

                let bothFilled = !draft.trimmedFront.isEmpty && !draft.trimmedBack.isEmpty
                let frontFilled = !draft.trimmedFront.isEmpty
                let progress: CGFloat = bothFilled ? 1.0 : (frontFilled ? 0.5 : 0)
                let barColor: Color = bothFilled ? .stateEasy : .gold

                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor)
                    .frame(width: geo.size.width * progress, height: 2)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 2)
    }

    private var quickAddBar: some View {
        Button {
            save(keepOpen: true)
        } label: {
            Text("＋ Ajouter la carte")
                .font(.uiButton)
                .foregroundStyle(Color.bgPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    draft.isValid
                        ? LinearGradient(colors: [.goldLight, .gold], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)], startPoint: .top, endPoint: .bottom),
                    in: .rect(cornerRadius: 14)
                )
        }
        .disabled(!draft.isValid)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.bgPrimary)
    }

    private func loadDeckInfo() async {
        let deckID = draft.deckID
        let descriptor = FetchDescriptor<Deck>(predicate: #Predicate { $0.id == deckID })
        do {
            guard let deck = try context.fetch(descriptor).first else { return }
            deckColor = deck.color ?? Color.goldHex
            deckName = deck.name
        } catch {
            Self.logger.error("Failed to load deck info: \(error.localizedDescription)")
        }
    }

    private func save(keepOpen: Bool) {
        guard draft.isValid else {
            error = .emptyField
            return
        }

        let deckID = draft.deckID
        let deckDescriptor = FetchDescriptor<Deck>(predicate: #Predicate { $0.id == deckID })

        do {
            guard let deck = try context.fetch(deckDescriptor).first else {
                error = .deckNotFound
                return
            }

            if let existingID = draft.existingID {
                let cardDescriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == existingID })
                guard let card = try context.fetch(cardDescriptor).first else {
                    error = .deckNotFound
                    return
                }
                card.front = draft.trimmedFront
                card.back = draft.trimmedBack
                card.syncVersion += 1
                card.syncStatus = SyncStatus.pendingUpdate.rawValue
            } else {
                let card = Card(
                    front: draft.trimmedFront,
                    back: draft.trimmedBack,
                    deck: deck,
                    nextReviewDate: .now,
                    syncStatus: SyncStatus.pendingCreate.rawValue
                )
                context.insert(card)
            }

            try context.save()
            savedCounter += 1

            if keepOpen {
                addedCount += 1
                draft = CardDraft(deckID: deckID)
                activeSegment = .question
                focusedField = .front
            } else {
                dismiss()
            }
        } catch {
            Self.logger.error("Failed to save card: \(error.localizedDescription)")
            self.error = .saveFailed(error.localizedDescription)
        }
    }
}
