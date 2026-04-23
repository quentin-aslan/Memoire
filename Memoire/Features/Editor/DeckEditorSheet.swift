import OSLog
import SwiftData
import SwiftUI

struct DeckEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var draft: DeckDraft
    @FocusState private var nameFocused: Bool
    @State private var error: EditorError?

    private let isEditing: Bool
    private let onCreated: ((Deck) -> Void)?
    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "DeckEditor")

    init(initialDraft: DeckDraft, onCreated: ((Deck) -> Void)? = nil) {
        _draft = State(initialValue: initialDraft)
        self.isEditing = initialDraft.isEditing
        self.onCreated = onCreated
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    iconPreview
                    nameField
                    colorPicker
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(Color.bgPrimary)
            .safeAreaInset(edge: .bottom) {
                if !isEditing {
                    Text("Vous ajouterez les cartes à l'étape suivante.")
                        .font(.sans(13))
                        .foregroundStyle(Color.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Enregistrer" : "Créer") { save() }
                        .bold()
                        .foregroundStyle(draft.isValid ? Color.gold : Color.textTertiary)
                        .disabled(!draft.isValid)
                }
            }
            .alert(item: $error) { err in
                Alert(title: Text("Erreur"), message: Text(err.errorDescription ?? ""))
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            try? await Task.sleep(for: .milliseconds(250))
            nameFocused = true
        }
    }

    private var iconPreview: some View {
        let selectedColor = Color(hex: draft.color)
        let lightColor = selectedColor.opacity(0.7)

        return ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [lightColor, selectedColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 88, height: 88)
                .shadow(color: selectedColor.opacity(0.4), radius: 16)
                .animation(.easeInOut(duration: 0.25), value: draft.color)

            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(Color.onGold)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NOM DU PAQUET")
                .font(.sans(11, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(Color.textSecondary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.bgCard)

                TextField("Ex : Japonais, Histoire…", text: $draft.name)
                    .font(.serif(20))
                    .foregroundStyle(Color.textPrimary)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .onChange(of: draft.name) { _, new in
                        if new.count > 40 { draft.name = String(new.prefix(40)) }
                    }
            }
            .frame(minHeight: 52)

            HStack {
                Spacer()
                Text("\(draft.name.count)/40")
                    .font(.sans(12))
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COULEUR")
                .font(.sans(11, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(Color.textSecondary)

            let columns = Array(repeating: GridItem(.flexible()), count: 8)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Color.deckPaletteHex, id: \.self) { hex in
                    colorSwatch(hex: hex)
                }
            }
        }
    }

    private func colorSwatch(hex: String) -> some View {
        let isSelected = draft.color == hex
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                draft.color = hex
            }
        } label: {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 36, height: 36)
                .scaleEffect(isSelected ? 1.15 : 1.0)
                .overlay(
                    Circle()
                        .strokeBorder(Color.gold, lineWidth: 2)
                        .opacity(isSelected ? 1 : 0)
                        .scaleEffect(isSelected ? 1.15 : 1.0)
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func save() {
        guard draft.isValid else {
            error = .emptyField
            return
        }

        do {
            if let existingID = draft.existingID {
                let descriptor = FetchDescriptor<Deck>(predicate: #Predicate { $0.id == existingID })
                guard let deck = try context.fetch(descriptor).first else {
                    error = .deckNotFound
                    return
                }
                deck.name = draft.trimmedName
                deck.color = draft.color
                deck.syncVersion += 1
                deck.syncStatus = SyncStatus.pendingUpdate.rawValue
            } else {
                let maxDescriptor = FetchDescriptor<Deck>(sortBy: [SortDescriptor(\.position, order: .reverse)])
                let maxPosition = try context.fetch(maxDescriptor).first?.position ?? -1
                let deck = Deck(name: draft.trimmedName, color: draft.color, position: maxPosition + 1, syncStatus: SyncStatus.pendingCreate.rawValue)
                context.insert(deck)
                try context.save()
                onCreated?(deck)
                dismiss()
                return
            }

            try context.save()
            dismiss()
        } catch {
            Self.logger.error("Failed to save deck: \(error.localizedDescription)")
            self.error = .saveFailed(error.localizedDescription)
        }
    }
}
