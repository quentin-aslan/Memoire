import SwiftUI

struct RootView: View {
    @Environment(\.appPreferences) private var prefs
    @Environment(\.deckCreation) private var deckCreation
    @State private var selectedTab: RootTab = .home

    var body: some View {
        Group {
            if prefs.hasOnboarded {
                mainTabs
            } else {
                OnboardingFlow()
            }
        }
        .animation(.easeInOut, value: prefs.hasOnboarded)
        .sheet(item: Binding(
            get: { deckCreation.draft },
            set: { deckCreation.draft = $0 }
        ), onDismiss: {
            if deckCreation.createdDeck != nil { selectedTab = .decks }
        }) { draft in
            DeckEditorSheet(initialDraft: draft, onCreated: { deck in
                deckCreation.createdDeck = deck
            })
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            Tab("Accueil", systemImage: "square.grid.2x2", value: RootTab.home) {
                NavigationStack {
                    HomeScreen(selectedTab: $selectedTab)
                }
            }

            Tab("Réviser", systemImage: "play.fill", value: RootTab.review) {
                NavigationStack {
                    ReviewTabScreen()
                }
            }

            Tab("Paquets", systemImage: "rectangle.stack", value: RootTab.decks) {
                DecksScreen()
            }

            Tab("Réglages", systemImage: "gearshape", value: RootTab.settings) {
                NavigationStack {
                    SettingsScreen()
                }
            }
        }
        .tint(.gold)
        .toolbarBackground(prefs.calmMode ? Color.bgPrimary : .clear, for: .tabBar)
        .toolbarBackground(prefs.calmMode ? Visibility.visible : .automatic, for: .tabBar)
    }
}

enum RootTab: Hashable {
    case home, review, decks, settings
}

#Preview {
    RootView()
        .environment(\.appPreferences, AppPreferences())
}
