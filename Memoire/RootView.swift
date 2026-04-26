import SwiftUI

struct RootView: View {
    @Environment(\.appPreferences) private var prefs
    @Environment(\.deckCreation) private var deckCreation
    @Environment(\.widgetLaunch) private var widgetLaunch
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
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == AppConstants.DeepLinks.scheme else { return }
        switch url.host {
        case "review":
            selectedTab = .home
            widgetLaunch.pendingAction = .startReview
        case "home":
            selectedTab = .home
        case "decks":
            if url.pathComponents.contains("new") {
                selectedTab = .decks
                deckCreation.open()
            } else {
                selectedTab = .decks
            }
        default:
            break
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            Tab("Accueil", systemImage: "square.grid.2x2", value: RootTab.home) {
                NavigationStack {
                    HomeScreen()
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
    case home, decks, settings
}

#Preview {
    RootView()
        .environment(\.appPreferences, AppPreferences())
}
