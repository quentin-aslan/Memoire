import SwiftUI

struct SettingsScreen: View {
    @Environment(\.appPreferences) private var prefs
    @Environment(\.openURL) private var openURL
    @FocusState private var firstNameFocused: Bool

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
}
