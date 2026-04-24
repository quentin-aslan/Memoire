import Foundation
import OSLog
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Wire format

struct BackupFile: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let decks: [DeckSnapshot]
    let cards: [CardSnapshot]
    let reviews: [ReviewSnapshot]
}

struct DeckSnapshot: Codable {
    let id: UUID
    let name: String
    let color: String?
    let position: Int
    let createdAt: Date
    let syncVersion: Int
    let syncStatus: Int
}

struct CardSnapshot: Codable {
    let id: UUID
    let deckID: UUID
    let front: String
    let back: String
    let backDrawing: Data?
    let createdAt: Date
    let fsrsDifficulty: Double
    let fsrsStability: Double
    let fsrsState: Int
    let fsrsLastReview: Date?
    let fsrsReps: Int
    let fsrsLapses: Int
    let nextReviewDate: Date?
    let learningStep: Int
    let syncVersion: Int
    let syncStatus: Int
}

struct ReviewSnapshot: Codable {
    let id: UUID
    let cardID: UUID
    let rating: Int
    let reviewedAt: Date
    let durationMs: Int?
    let syncVersion: Int
    let syncStatus: Int
}

// MARK: - Errors

enum BackupError: LocalizedError {
    case unsupportedSchemaVersion(found: Int, supported: Int)
    case decodingFailed(underlying: Error)
    case encodingFailed(underlying: Error)
    case persistenceFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let found, let supported):
            return "Sauvegarde version \(found) non supportée (max : \(supported)). Mets à jour l'app."
        case .decodingFailed:
            return "Fichier de sauvegarde invalide."
        case .encodingFailed:
            return "Impossible de générer la sauvegarde."
        case .persistenceFailed:
            return "Échec de l'import. La base est restée vide — réessaie avec un fichier valide."
        }
    }
}

// MARK: - Service

@MainActor
enum BackupService {
    private static let logger = Logger(
        subsystem: AppConstants.Logging.subsystem,
        category: "Backup"
    )

    static func export(context: ModelContext) throws -> Data {
        // Les soft-deleted sont exclus de la sauvegarde — cohérent avec le
        // filtrage des listes côté UI. Review n'a pas de soft-delete.
        let deckDescriptor = FetchDescriptor<Deck>(predicate: #Predicate { !$0.isSoftDeleted })
        let cardDescriptor = FetchDescriptor<Card>(predicate: #Predicate { !$0.isSoftDeleted })
        let reviewDescriptor = FetchDescriptor<Review>()

        let decks = try context.fetch(deckDescriptor)
        let cards = try context.fetch(cardDescriptor)
        let reviews = try context.fetch(reviewDescriptor)

        let cardSnapshots = cards.compactMap { card -> CardSnapshot? in
            guard let snapshot = CardSnapshot(card) else {
                logger.warning("Skipping deckless card \(card.id, privacy: .public) during export")
                return nil
            }
            return snapshot
        }

        let file = BackupFile(
            schemaVersion: AppConstants.Backup.currentSchemaVersion,
            exportedAt: .now,
            decks: decks.map(DeckSnapshot.init),
            cards: cardSnapshots,
            reviews: reviews.map(ReviewSnapshot.init)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(file)
            logger.info("Exported \(file.decks.count) decks, \(file.cards.count) cards, \(file.reviews.count) reviews")
            return data
        } catch {
            throw BackupError.encodingFailed(underlying: error)
        }
    }

    static func replaceAll(from data: Data, context: ModelContext) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let file: BackupFile
        do {
            file = try decoder.decode(BackupFile.self, from: data)
        } catch {
            throw BackupError.decodingFailed(underlying: error)
        }

        guard file.schemaVersion <= AppConstants.Backup.currentSchemaVersion else {
            throw BackupError.unsupportedSchemaVersion(
                found: file.schemaVersion,
                supported: AppConstants.Backup.currentSchemaVersion
            )
        }

        // Wipe puis insert séparés par un save : @Attribute(.unique) sur UUID throw
        // au save (pas à l'insert), donc delete et insert du même UUID dans une
        // seule transaction sont fragiles. Si l'insert échoue, on rollback l'insert
        // uniquement — la base reste vide, état cohérent, retry safe.
        do {
            try wipe(context: context)
            try insert(file: file, context: context)
        } catch let error as BackupError {
            context.rollback()
            throw error
        } catch {
            context.rollback()
            throw BackupError.persistenceFailed(underlying: error)
        }
    }

    // MARK: - Private

    private static func wipe(context: ModelContext) throws {
        let reviews = try context.fetch(FetchDescriptor<Review>())
        let cards = try context.fetch(FetchDescriptor<Card>())
        let decks = try context.fetch(FetchDescriptor<Deck>())

        reviews.forEach(context.delete)
        cards.forEach(context.delete)
        decks.forEach(context.delete)

        try context.save()
        logger.info("Wiped \(decks.count) decks, \(cards.count) cards, \(reviews.count) reviews")
    }

    private static func insert(file: BackupFile, context: ModelContext) throws {
        // Un seul save à la fin : si quoi que ce soit throw, context.rollback() dans
        // le catch de replaceAll remet tout ce bloc à zéro — la base reste vide
        // (post-wipe) et cohérente avec le message d'erreur affiché.
        var decksByID: [UUID: Deck] = [:]
        for snapshot in file.decks {
            let deck = snapshot.makeDeck()
            context.insert(deck)
            decksByID[deck.id] = deck
        }

        var insertedCardIDs: Set<UUID> = []
        for snapshot in file.cards {
            guard let deck = decksByID[snapshot.deckID] else {
                logger.warning("Dropping orphan card \(snapshot.id, privacy: .public): deck \(snapshot.deckID, privacy: .public) not found")
                continue
            }
            let card = snapshot.makeCard(deck: deck)
            context.insert(card)
            insertedCardIDs.insert(card.id)
        }

        var insertedReviewCount = 0
        for snapshot in file.reviews {
            guard insertedCardIDs.contains(snapshot.cardID) else {
                logger.warning("Dropping orphan review \(snapshot.id, privacy: .public): card \(snapshot.cardID, privacy: .public) not found")
                continue
            }
            context.insert(snapshot.makeReview())
            insertedReviewCount += 1
        }

        try context.save()
        logger.info("Imported \(decksByID.count) decks, \(insertedCardIDs.count) cards, \(insertedReviewCount) reviews")
    }
}

// MARK: - Snapshot <-> Model

private extension DeckSnapshot {
    init(_ deck: Deck) {
        self.id = deck.id
        self.name = deck.name
        self.color = deck.color
        self.position = deck.position
        self.createdAt = deck.createdAt
        self.syncVersion = deck.syncVersion
        self.syncStatus = deck.syncStatus
    }

    func makeDeck() -> Deck {
        Deck(
            id: id,
            name: name,
            color: color,
            position: position,
            createdAt: createdAt,
            syncVersion: syncVersion,
            syncStatus: syncStatus
        )
    }
}

private extension CardSnapshot {
    init?(_ card: Card) {
        guard let deckID = card.deck?.id else { return nil }
        self.id = card.id
        self.deckID = deckID
        self.front = card.front
        self.back = card.back
        self.backDrawing = card.backDrawing
        self.createdAt = card.createdAt
        self.fsrsDifficulty = card.fsrsDifficulty
        self.fsrsStability = card.fsrsStability
        self.fsrsState = card.fsrsState
        self.fsrsLastReview = card.fsrsLastReview
        self.fsrsReps = card.fsrsReps
        self.fsrsLapses = card.fsrsLapses
        self.nextReviewDate = card.nextReviewDate
        self.learningStep = card.learningStep
        self.syncVersion = card.syncVersion
        self.syncStatus = card.syncStatus
    }

    func makeCard(deck: Deck) -> Card {
        Card(
            id: id,
            front: front,
            back: back,
            backDrawing: backDrawing,
            deck: deck,
            createdAt: createdAt,
            fsrsDifficulty: fsrsDifficulty,
            fsrsStability: fsrsStability,
            fsrsState: fsrsState,
            fsrsLastReview: fsrsLastReview,
            fsrsReps: fsrsReps,
            fsrsLapses: fsrsLapses,
            nextReviewDate: nextReviewDate,
            learningStep: learningStep,
            syncVersion: syncVersion,
            syncStatus: syncStatus
        )
    }
}

private extension ReviewSnapshot {
    init(_ review: Review) {
        self.id = review.id
        self.cardID = review.cardID
        self.rating = review.rating
        self.reviewedAt = review.reviewedAt
        self.durationMs = review.durationMs
        self.syncVersion = review.syncVersion
        self.syncStatus = review.syncStatus
    }

    func makeReview() -> Review {
        Review(
            id: id,
            cardID: cardID,
            rating: rating,
            reviewedAt: reviewedAt,
            durationMs: durationMs,
            syncVersion: syncVersion,
            syncStatus: syncStatus
        )
    }
}

// MARK: - FileDocument wrapper

struct BackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]
    static let writableContentTypes: [UTType] = [.json]

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let payload = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = payload
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
