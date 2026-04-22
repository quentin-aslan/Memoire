# ADR 0006 — `AppPreferences` UserDefaults temporaire vs `UserSettings @Model`

**Date** : 2026-04-18
**Statut** : Accepté avec migration V1.1 prévue

## Contexte

Le CDC §6.4 spécifie un modèle `UserSettings` (SwiftData `@Model`) contenant les réglages utilisateur avec tous les champs syncables vers Supabase en V1.1 :

```
UserSettings: dailyNewCards=10, sessionTimeLimit=15min, desiredRetention=0.90,
              notificationHour=18, regularityDays=[Date] (30 derniers jours)
```

En parallèle, certains réglages sont purement UI et ne doivent **jamais** se synchroniser cross-device :
- `hasOnboarded: Bool` — propre à l'installation
- `calmMode: Bool` — dépend de la sensibilité visuelle de l'utilisateur sur CE device (la même personne peut être sensible sur iPhone Pro OLED et pas sur son ancien iPad LCD, ou vice-versa)

Trois options :

- **Tout dans `AppPreferences` (UserDefaults)** — simple mais ne se sync pas → incorrect pour les vrais settings (session time, daily cards…)
- **Tout dans `UserSettings @Model`** — sync-ready mais UserDefaults serait plus idiomatique pour des flags UI-only
- **Split : AppPreferences (UI-only) + UserSettings @Model (syncables)** — correct architecturalement mais ajoute une couche en V1.0

## Décision

**Pour le MVP V1.0, tout vit dans `AppPreferences` UserDefaults-backed.** Migration vers `UserSettings @Model` planifiée en V1.1 (P8 du plan d'implémentation).

`AppPreferences` actuel (`Mémoire/AppPreferences.swift`) :

```swift
@Observable
final class AppPreferences {
    static let shared = AppPreferences()
    var hasOnboarded: Bool { /* UserDefaults-backed via didSet */ }
    var calmMode: Bool { ... }
    var notificationHour: Int = 18 { ... }
    var dailyNewCards: Int = 10 { ... }
}

extension EnvironmentValues {
    @Entry var appPreferences: AppPreferences = .shared
}
```

Accessible partout via `@Environment(\.appPreferences)`. Le default `.shared` évite les crashes de previews (cf [ADR-0002](0002-liquid-glass-chrome-only.md) note P3.5 — correction Entry pattern).

Quand la migration V1.1 arrivera :
- Les prefs syncables (`notificationHour`, `dailyNewCards`, `sessionTimeLimit`, `desiredRetention`, `regularityDays`) déménagent vers `UserSettings @Model`
- Les prefs UI-only (`hasOnboarded`, `calmMode`) restent dans `AppPreferences` / UserDefaults
- Script de migration au premier lancement post-update : lit les valeurs actuelles UserDefaults, crée une instance `UserSettings` avec, **sans** supprimer les UserDefaults (idempotence si migration rollback)

## Conséquences

**Positives** :
- MVP livrable plus vite : une seule source de prefs en V1.0
- `@Entry` + `AppPreferences.shared` garantit qu'aucune vue (app ou preview) ne crashe si l'injection n'a pas eu lieu
- `@Observable` class → les previews Xcode réagissent aux changements de prefs
- Pattern familier (Apple doc WWDC24 « What's new in SwiftUI ») pour les contributeurs

**Négatives** :
- Les réglages théoriquement syncables (`notificationHour`, `dailyNewCards`) seront re-paramétrés par l'utilisateur sur chaque nouveau device en V1.0. **Acceptable** : V1.0 est mono-device, la sync n'existe pas
- Migration V1.1 non triviale : doit garantir idempotence et rollback safety
- Dette technique explicite : doit être levée avant d'activer la sync Supabase

## Alternatives considérées

- **Tout dans `UserSettings @Model` dès V1.0** — rejeté : over-engineering pour le MVP, ajoute une couche (injection, @Query, singleton bootstrap) pour aucun gain utilisateur tant que la sync n'existe pas
- **Split dès V1.0** — rejeté : doublement de l'infrastructure de prefs pour V1.0, refactor de tous les `@Environment(\.appPreferences)` quand le split arrivera anyway → autant faire le refactor en une passe lors de la migration V1.1
