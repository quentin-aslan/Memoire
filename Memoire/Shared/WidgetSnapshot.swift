import Foundation
import OSLog

// Single source of truth between the app (writer) and the widget (reader).
// The struct deliberately depends only on Foundation so it can compile in
// the widget extension without pulling SwiftData into a memory-tight process.
struct WidgetSnapshot: Codable, Sendable {
    var hasAnyDeck: Bool
    var dueNow: Int
    var reviewedToday: Int
    var totalToday: Int
    var nextDueDate: Date?
    var laterTodayCount: Int
    var streakDays: Int
    var generatedAt: Date
    var schemaVersion: Int

    static let currentSchemaVersion = 1

    static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppConstants.Widget.appGroupID)?
            .appendingPathComponent(AppConstants.Widget.snapshotFile)
    }

    static func read() -> WidgetSnapshot? {
        guard let url = fileURL,
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(WidgetSnapshot.self, from: data)
            // Schema-drift guard: an old widget binary reading a newer snapshot
            // (or vice versa) falls through to the resolver's `.onboarding`
            // neutral state rather than rendering stale or wrong fields.
            guard decoded.schemaVersion == currentSchemaVersion else {
                Self.logger.error("Snapshot schemaVersion mismatch: got \(decoded.schemaVersion), expected \(currentSchemaVersion)")
                return nil
            }
            return decoded
        } catch {
            Self.logger.error("Failed to decode snapshot: \(error.localizedDescription)")
            return nil
        }
    }

    static func write(_ snapshot: WidgetSnapshot) throws {
        guard let url = fileURL else {
            throw SnapshotError.appGroupUnavailable
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: .atomic)
    }

    enum SnapshotError: Error {
        case appGroupUnavailable
    }

    private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "WidgetSnapshot")
}
