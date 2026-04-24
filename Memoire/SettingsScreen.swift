import SwiftUI
#if DEBUG
import OSLog
import SwiftData
import UniformTypeIdentifiers
#endif

struct SettingsScreen: View {
    @Environment(\.appPreferences) private var prefs
    @Environment(\.openURL) private var openURL
    @FocusState private var firstNameFocused: Bool

    #if DEBUG
    @Environment(\.modelContext) private var modelContext

    @State private var isExporting = false
    @State private var isImporting = false
    @State private var pendingExport: BackupDocument?
    @State private var backupAlert: String?

    private static let debugLogger = Logger(
        subsystem: AppConstants.Logging.subsystem,
        category: "Settings"
    )
    #endif

    private static let mailSubject = "Mémoire — Bug / Question"

    var body: some View {
        @Bindable var prefs = prefs

        Form {
            Section {
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
            } header: {
                Text("Vous")
                    .foregroundStyle(Color.gold)
            } footer: {
                Text("Utilisé pour personnaliser la salutation de l'accueil.")
                    .font(.sans(12))
                    .foregroundStyle(Color.textTertiary)
            }

            Section {
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
                Text("Accessibilité")
                    .foregroundStyle(Color.gold)
            }

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
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0 (MVP)")
                        .foregroundStyle(Color.textSecondary)
                }
                HStack {
                    Text("Développeur")
                    Spacer()
                    Text("Quentin Aslan")
                        .foregroundStyle(Color.textSecondary)
                }
            } header: {
                Text("À propos")
                    .foregroundStyle(Color.gold)
            }

            if let url = supportMailURL {
                Section {
                    Button {
                        openURL(url)
                    } label: {
                        Text("Signaler un bug ou contacter")
                    }
                    .buttonStyle(.primary)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
                .listSectionSpacing(.compact)
            }

            #if DEBUG
            Section {
                Button {
                    prefs.hasOnboarded = false
                } label: {
                    Text("Rejouer l'onboarding")
                        .foregroundStyle(Color.stateAgain)
                }

                Button {
                    prepareExport()
                } label: {
                    Text("Exporter la base (dev)")
                }

                Button {
                    isImporting = true
                } label: {
                    Text("Importer une base (dev)")
                }
            } header: {
                Text("Debug")
                    .foregroundStyle(Color.gold)
            }
            #endif
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
        .navigationTitle("Réglages")
        .navigationBarTitleDisplayMode(.inline)
        #if DEBUG
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

    #if DEBUG
    private func prepareExport() {
        do {
            let data = try BackupService.export(context: modelContext)
            pendingExport = BackupDocument(data: data)
            isExporting = true
        } catch {
            Self.debugLogger.error("Export failed: \(error.localizedDescription)")
            backupAlert = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        pendingExport = nil
        switch result {
        case .success(let url):
            Self.debugLogger.info("Export saved to \(url.path, privacy: .public)")
            backupAlert = "Sauvegarde enregistrée."
        case .failure(let error):
            Self.debugLogger.info("Export dismissed: \(error.localizedDescription)")
        }
    }

    private func handleImportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            importBackup(from: url)
        case .failure(let error):
            Self.debugLogger.info("Import dismissed: \(error.localizedDescription)")
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
            Self.debugLogger.error("Import failed: \(error.localizedDescription)")
            backupAlert = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func defaultBackupFilename() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let stamp = formatter.string(from: .now).replacingOccurrences(of: ":", with: "-")
        return "memoire-backup-\(stamp).\(AppConstants.Backup.fileExtension)"
    }
    #endif
}
