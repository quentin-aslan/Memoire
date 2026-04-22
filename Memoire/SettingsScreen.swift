import SwiftUI

struct SettingsScreen: View {
    @Environment(\.appPreferences) private var prefs

    var body: some View {
        @Bindable var prefs = prefs

        Form {
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
            } header: {
                Text("À propos")
                    .foregroundStyle(Color.gold)
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

}
