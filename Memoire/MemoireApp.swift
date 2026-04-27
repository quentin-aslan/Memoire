//
//  MemoireApp.swift
//  Memoire
//
//  Created by Quentin Aslan on 18/04/2026.
//

import SwiftData
import SwiftUI

@main
struct MemoireApp: App {
    @State private var prefs = AppPreferences()
    @State private var deckCreation = DeckCreationCoordinator()
    @State private var widgetLaunch = WidgetLaunchCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let bgPrimary   = UIColor(red: 0x1C/255, green: 0x1C/255, blue: 0x1E/255, alpha: 1)
        let bgCard      = UIColor(red: 0x2C/255, green: 0x2C/255, blue: 0x2E/255, alpha: 1)
        let textPrimary = UIColor(red: 0xF5/255, green: 0xF5/255, blue: 0xF7/255, alpha: 1)
        let gold        = UIColor(red: 0xD4/255, green: 0xAF/255, blue: 0x37/255, alpha: 1)

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = bgPrimary
        nav.titleTextAttributes      = [.foregroundColor: textPrimary]
        nav.largeTitleTextAttributes = [.foregroundColor: textPrimary]
        nav.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance   = nav
        UINavigationBar.appearance().compactAppearance    = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().tintColor            = gold

        UITableViewCell.appearance().backgroundColor = bgCard
    }

    let container: ModelContainer = {
        do {
            let container = try ModelContainer(for: Deck.self, Card.self, Review.self)
            SchedulerMigration.runIfNeeded(in: container.mainContext)
            return container
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appPreferences, prefs)
                .environment(\.deckCreation, deckCreation)
                .environment(\.widgetLaunch, widgetLaunch)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, newPhase in
                    // `.active` → re-schedule one-shot notifications so days with no
                    // cards due are silently skipped. `.inactive` is excluded — it fires
                    // on every banner/Control Center pull for no benefit.
                    if newPhase == .active {
                        Task { await NotificationScheduler.refresh(context: container.mainContext, prefs: prefs) }
                    } else if newPhase == .background {
                        WidgetSnapshotWriter.refresh(context: container.mainContext, prefs: prefs)
                    }
                }
                .onChange(of: prefs.notificationHour) { _, _ in
                    Task { await NotificationScheduler.refresh(context: container.mainContext, prefs: prefs) }
                }
        }
        .modelContainer(container)
    }
}
