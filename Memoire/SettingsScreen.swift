import SwiftUI
import OSLog
import SwiftData
import UniformTypeIdentifiers

struct SettingsScreen: View {
    @Environment(\.appPreferences) private var prefs
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @FocusState private var firstNameFocused: Bool

    @State private var isExporting = false
    @State private var isImporting = false
    @State private var pendingExport: BackupDocument?
    @State private var pendingImportURL: URL?
    @State private var backupAlert: String?
    #if DEBUG
    @State private var testNotifAlertShown = false
    #endif

    private static let backupLogger = Logger(
        subsystem: AppConstants.Logging.subsystem,
        category: "Settings"
    )

    private static let mailSubject = "Mémoire — Bug / Question"

    var body: some View {
        @Bindable var prefs = prefs

        Form {
            Section {
                Picker("Heure du rappel", selection: $prefs.notificationHour) {
                    ForEach(6..<24, id: \.self) { hour in
                        Text("\(hour)h").tag(hour)
                    }
                }

                Stepper(value: $prefs.dailyNewCards, in: 1...50) {
                    HStack {
                        Text("Nouvelles cartes / jour")
                        Spacer()
                        Text("\(prefs.dailyNewCards)")
                            .foregroundStyle(Color.gold)
                            .monospacedDigit()
                    }
                }
            } header: {
                Text("Révisions")
                    .foregroundStyle(Color.gold)
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Prénom (optionnel)", text: Binding(
                        get: { prefs.firstName ?? "" },
                        set: { prefs.firstName = $0 }
                    ))
                    .font(.sans(15))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($firstNameFocused)
                    .submitLabel(.done)
                    .onSubmit { firstNameFocused = false }

                    Text("Personnalise la salutation de l'accueil.")
                        .font(.sans(12))
                        .foregroundStyle(Color.textTertiary)
                }

                Toggle(isOn: $prefs.calmMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mode Calme")
                            .font(.sans(15, weight: .medium))
                        Text("Désactive les effets translucides.")
                            .font(.sans(12))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .tint(.gold)
            } header: {
                Text("Apparence & vous")
                    .foregroundStyle(Color.gold)
            }

            Section {
                Button {
                    prepareExport()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(Color.gold)
                            .frame(width: 24)
                        Text("Exporter une sauvegarde")
                            .foregroundStyle(Color.textPrimary)
                    }
                }

                Button {
                    isImporting = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(Color.gold)
                            .frame(width: 24)
                        Text("Restaurer une sauvegarde")
                            .foregroundStyle(Color.textPrimary)
                    }
                }
            } header: {
                Text("Sauvegarde")
                    .foregroundStyle(Color.gold)
            } footer: {
                Text("Exporte un fichier JSON contenant tes paquets, cartes et historique. La restauration remplace intégralement la base actuelle.")
                    .font(.sans(12))
                    .foregroundStyle(Color.textTertiary)
            }

            Section {
                if let url = supportMailURL {
                    Button {
                        openURL(url)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(Color.gold)
                                .frame(width: 24)
                            Text("Contacter ou signaler un bug")
                                .foregroundStyle(Color.textPrimary)
                        }
                    }
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                }

                HStack(spacing: 6) {
                    Text("Mémoire 1.0")
                        .foregroundStyle(Color.textSecondary)
                    Text("·")
                        .foregroundStyle(Color.textTertiary)
                    Text("Quentin Aslan")
                        .foregroundStyle(Color.textSecondary)
                }
                .font(.sans(14))
            } header: {
                Text("À propos")
                    .foregroundStyle(Color.gold)
            }

            #if DEBUG
            Section {
                DisclosureGroup {
                    Button {
                        prefs.hasOnboarded = false
                    } label: {
                        Text("Rejouer l'onboarding")
                            .foregroundStyle(Color.stateAgain)
                    }

                    Button {
                        Task {
                            await NotificationScheduler.sendTestNotification(context: modelContext, prefs: prefs)
                            testNotifAlertShown = true
                        }
                    } label: {
                        Text("Tester la notification")
                            .foregroundStyle(Color.gold)
                    }
                } label: {
                    Text("Avancé")
                        .font(.sans(15, weight: .medium))
                        .foregroundStyle(Color.gold)
                }
            }
            #endif
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
        .navigationTitle("Réglages")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $isExporting,
            document: pendingExport,
            contentType: .json,
            defaultFilename: defaultBackupFilename()
        ) { result in
            handleExportResult(result)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json]
        ) { result in
            handleImportResult(result)
        }
        .alert(
            "Restaurer la sauvegarde ?",
            isPresented: Binding(
                get: { pendingImportURL != nil },
                set: { if !$0 { pendingImportURL = nil } }
            ),
            presenting: pendingImportURL
        ) { url in
            Button("Annuler", role: .cancel) { pendingImportURL = nil }
            Button("Restaurer", role: .destructive) {
                pendingImportURL = nil
                importBackup(from: url)
            }
        } message: { _ in
            Text("Cette action remplace tous tes paquets, cartes et historique actuels. Elle est irréversible.")
        }
        .alert(
            "Sauvegarde",
            isPresented: Binding(
                get: { backupAlert != nil },
                set: { if !$0 { backupAlert = nil } }
            ),
            presenting: backupAlert
        ) { _ in
            Button("OK", role: .cancel) { backupAlert = nil }
        } message: { message in
            Text(message)
        }
        #if DEBUG
        .alert("Notification envoyée", isPresented: $testNotifAlertShown) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Mets l'app en arrière-plan dans les 5 secondes pour la voir.")
        }
        #endif
    }

    private var supportMailURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppConstants.Support.contactEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: Self.mailSubject),
        ]
        return components.url
    }

    private func prepareExport() {
        do {
            let data = try BackupService.export(context: modelContext)
            pendingExport = BackupDocument(data: data)
            isExporting = true
        } catch {
            Self.backupLogger.error("Export failed: \(error.localizedDescription)")
            backupAlert = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        pendingExport = nil
        switch result {
        case .success(let url):
            Self.backupLogger.info("Export saved to \(url.path, privacy: .public)")
            backupAlert = "Sauvegarde enregistrée."
        case .failure(let error):
            Self.backupLogger.info("Export dismissed: \(error.localizedDescription)")
        }
    }

    private func handleImportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            pendingImportURL = url
        case .failure(let error):
            Self.backupLogger.info("Import dismissed: \(error.localizedDescription)")
        }
    }

    private func importBackup(from url: URL) {
        // L'URL du fileImporter est security-scoped : sans ce cycle, read() lève EPERM
        // sur iCloud Drive ou tout provider tiers (Files, Dropbox, etc.).
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            try BackupService.replaceAll(from: data, context: modelContext)
            backupAlert = "Import réussi."
        } catch {
            Self.backupLogger.error("Import failed: \(error.localizedDescription)")
            backupAlert = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func defaultBackupFilename() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let stamp = formatter.string(from: .now).replacingOccurrences(of: ":", with: "-")
        return "memoire-backup-\(stamp).\(AppConstants.Backup.fileExtension)"
    }
}
