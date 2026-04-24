# Mémoire

App iOS de répétition espacée (FSRS) optimisée pour adultes TDAH. Esthétique « dark luxury » — or mat `#D4AF37`, serif New York, Liquid Glass sur le chrome uniquement.

## Stack

- **SwiftUI** — iOS 18.0 deployment target, iOS 26 progressive enhancement pour Liquid Glass
- **SwiftData** — persistence locale. Champs sync prêts (`isSoftDeleted`, `syncVersion`, `syncStatus`) mais **Supabase reporté V1.1**
- **swift-fsrs** — algo de répétition espacée FSRS v5 (package SPM, `ShortTermScheduler`)
- **Xcode 26+ / Swift 5** — build avec SDK iOS 26

## Commandes build

**⚠️ Important** — la destination par défaut du projet Xcode peut être un iPhone physique (signing requis). Pour build sans team :

```bash
cd "/Users/quentinaslan/DEV/Mémoire"
scheme=$(xcodebuild -list 2>/dev/null | awk '/Schemes:/{found=1; next} found && NF{gsub(/^ +| +$/, "", $0); print; exit}')
xcodebuild -project "Memoire.xcodeproj" -scheme "$scheme" -destination 'generic/platform=iOS Simulator' build
```

Attention : seul le **dossier du repo** s'écrit `Mémoire` avec accent — le `.xcodeproj`, le target et le scheme s'écrivent tous `Memoire` (sans accent). Le `awk` ci-dessus trim simplement les espaces de l'output `xcodebuild -list`.

Si le MCP Xcode est connecté (`mcp__xcode__BuildProject`) : il utilise la destination active dans Xcode → échoue si iPhone physique sélectionné sans Team.

## Structure

```
Memoire/
  MemoireApp.swift           entrée @main + ModelContainer + UIKit Appearance + env injection
  ContentView.swift          délègue à RootView
  RootView.swift             TabView + branchement onboarding/tabs + toolbarBackground calmMode
  AppPreferences.swift       @Observable UserDefaults-backed (prefs UI-only)
  AppRoute.swift             enum Hashable pour type-safe nav
  DeckCreationCoordinator.swift  coordonne flow création deck entre Home et Decks

  Color+Tokens.swift         palette (init(hex:) + tokens sémantiques)
  Typography.swift           Font.serif/.sans + styles nommés
  GlassSurface.swift         modificateur .memoireSurface (unique point d'entrée glass)
  ProgressRing.swift         composant d'anneau réutilisable
  PrimaryButton.swift        PrimaryButtonStyle (dégradé or) partagé

  HomeScreen.swift           Accueil (anneau + régularité + CTA)
  DecksScreen.swift          liste paquets (+ reorder + swipe delete + "+" create)
  DeckDetailScreen.swift     détail paquet (liste cartes + "+" create)
  CardDetailScreen.swift     détail carte (section MÉMORISATION : état, difficulté, stabilité)
  ReviewScreen.swift         session de révision (flip 3D + ratings)
  ReviewSession.swift        @Observable state transient de session (re-queue .again)
  CompleteScreen.swift       fin de session
  Rating.swift               enum 3 cas : .again / .good / .easy → "À revoir / Moyen / Facile"
  OnboardingFlow.swift       4 pages avec sensibilité + rappel
  SettingsScreen.swift       Form (Mode Calme, notif, cartes/jour, Signaler un bug)
  EmptyDecksState.swift      empty state liste paquets (CTA + illustration)
  EmptyDueState.swift        empty state « à jour » (avec variante « revenez plus tard »)

  Models/                    SwiftData @Model classes
    Deck.swift
    Card.swift               inclut `learningStep: Int` (palier avant graduation FSRS)
    Review.swift
    SyncStatus.swift         enum Int (synced/pendingCreate/pendingUpdate/pendingDelete)

  AppConstants.swift         constantes partagées (Logger subsystem, notification ID, FSRS bounds, LearningSteps.steps…)

  Scheduling/                algorithme FSRS
    FSRSState.swift          enum FSRSState (new/learning/review/relearning) — abstraction call-site
    FSRSScheduler.swift      wrapper ShortTermScheduler
    CardFSRSAdapter.swift    snapshot Card ↔ SwiftFSRS.Card + Rating → SwiftFSRS.Rating
    DailyQueue.swift         file quotidienne (due non-nouvelles + nouvelles plafonnées)
    SchedulerMigration.swift migration one-shot FSRS au premier lancement

  Features/
    DeleteConfirmationSheet.swift   sheet modale de confirmation delete (cascade deck → cartes)
    Editor/                         CRUD deck/carte
      DeckDraft.swift
      CardDraft.swift
      DeckEditorSheet.swift    sheet modale création/édition deck
      CardEditorSheet.swift    sheet modale avec "Enregistrer et ajouter une autre"
      EditorError.swift

  Services/
    NotificationScheduler.swift  notifications quotidiennes
    RegularityCalculator.swift   score de régularité (30 jours glissants)

docs/adr/                    décisions architecturales documentées
```

## Conventions fortes

### Code in English

Tous les identifiants (variables, fonctions, types, enums, commentaires) sont en anglais.

**Exception** : les strings affichées à l'utilisateur (`Text()`, `.accessibilityLabel()`, `.navigationTitle()`, placeholders) restent en français — c'est une app française.

Les commentaires expliquent le **WHY**, jamais le WHAT. Un commentaire qui se lit comme le code lui-même doit être supprimé.

### No magic numbers or strings

Toute valeur avec une signification métier ou partagée entre plusieurs fichiers doit vivre dans une constante nommée.

**`AppConstants.swift`** — source unique pour :
- `AppConstants.Logging.subsystem` → remplace `"com.memoire.app"` partout
- `AppConstants.Notifications.dailyReviewID`
- `AppConstants.FSRS.defaultRetention / minRetention / maxRetention`
- `AppConstants.FSRS.easyDifficultyThreshold / mediumDifficultyThreshold`
- `AppConstants.Regularity.windowDays`
- `AppConstants.Onboarding.pageCount`

**`Color+Tokens.swift`** — `Color.goldHex` est la source unique de la valeur `"#D4AF37"` utilisée comme string de couleur par défaut.

**`Scheduling/FSRSState.swift`** — `enum FSRSState: Int` abstrait les raw Int `0/1/2/3` de `Card.fsrsState` aux call sites. Le stockage SwiftData reste `Int` pour éviter une migration de schéma.

**Exceptions documentées** : paddings SwiftUI à usage unique (`.padding(20)`), durations d'animation, corner radii — ne pas factoriser si non partagés entre fichiers.

### Glass chrome-only

**Seul point d'entrée Liquid Glass** : `.memoireSurface(in:tint:interactive:)` dans `GlassSurface.swift`. Respecte automatiquement `accessibilityReduceTransparency`, `prefs.calmMode`, et la disponibilité iOS 26.

**Mode Calme désactive TOUT le glass** : en plus de `memoireSurface`, la tab bar glass est contrôlée via `.toolbarBackground(prefs.calmMode ? Color.bgPrimary : .clear, for: .tabBar)` dans `RootView`. Tout nouveau glass ajouté doit aussi respecter `prefs.calmMode`.

Interdit :
- `.glassEffect()` direct (contournement du fallback + doctrine chrome-only)
- `.glassEffect(.clear)` (banni par le brief)
- Glass sur **contenu éditorial** (carte de révision, listes, texte long). Tout ce qui porte la typo New York vit sur surface **solide** (`surfaceElevated` ou `surfaceRaised`).

Glass uniquement sur : tab bar (auto iOS 26), toolbars, sheets, CTA paywall, boutons FSRS.

### Pas de magic strings

Toute chaîne utilisée comme identifiant (clé UserDefaults, nom de notification, predicate, analytics event) doit vivre dans une `enum` ou `static let` nommée — jamais inline. Voir aussi la section **No magic numbers or strings** ci-dessus.

```swift
// ✗
UserDefaults.standard.bool(forKey: "prefs.calmMode")
// ✓
UserDefaults.standard.bool(forKey: Keys.calmMode)  // Keys est un enum privé dans AppPreferences
```

### Session de révision — re-queue "À revoir"

`ReviewSession.rate()` réappend la carte en fin de `cards` à chaque notation `.again`. Pas de cap. La carte revient jusqu'à notation "Moyen" ou "Facile" — comportement FSRS/Anki standard. `totalCount` augmente dynamiquement, ce n'est pas un bug.

### Learning steps avant FSRS

Les cartes nouvelles + les cartes en relearning passent par des **paliers fixes** (`AppConstants.LearningSteps.steps`) avant d'entrer en `.review` piloté par FSRS. Le palier courant vit dans `Card.learningStep: Int` (0 = premier palier, -1 = graduée). `ReviewSession.rate()` intercepte la notation avant de déléguer au scheduler. Cf [ADR-0007](docs/adr/0007-learning-steps.md).

### Design tokens

Pas de couleurs hex en dur dans les vues. Utiliser `Color.bgPrimary`, `Color.gold`, `Color.goldTint`, etc. depuis `Color+Tokens.swift`.

Pas de `.system(size:)` en dur. Utiliser `Font.serif(_:)`, `Font.sans(_:)`, ou les styles nommés (`.uiButton`, `.cardQuestion`, …) depuis `Typography.swift`.

### UIKit Appearance

Tout override UIKit global (nav bar, table view cells) est centralisé dans `MemoireApp.init()`. Ne pas appeler `UINavigationBar.appearance()` ou `UITableViewCell.appearance()` ailleurs. `UIWindow.appearance().overrideUserInterfaceStyle` est un no-op (pas un `UI_APPEARANCE_SELECTOR`) — ne pas l'utiliser.

### Édition SwiftData

Pour toute UI d'édition : utiliser un **draft struct** value-type (`DeckDraft`, `CardDraft`), jamais `@Bindable` direct sur un `@Model`. Le commit se fait uniquement au Save explicite. Cf [ADR-0004](docs/adr/0004-draft-struct-editing.md).

### Soft delete

Jamais `context.delete(model)`. Toujours :
```swift
deck.isSoftDeleted = true
deck.deletedAt = .now
deck.syncVersion += 1
deck.syncStatus = SyncStatus.pendingDelete.rawValue
```
Filtrage dans les vues via `.filter { !$0.isSoftDeleted }` ou predicate SwiftData. Attention : le champ s'appelle `isSoftDeleted` (et non `isDeleted`) pour ne pas shadower `PersistentModel.isDeleted` de SwiftData — shadowing qui empêchait la persistance du flag.

### Environment

`AppPreferences` est accessible partout via `@Environment(\.appPreferences)` (pattern `@Entry`, défaut `.shared` pour ne jamais crasher les previews). Injection en prod dans `MemoireApp`.

### Error handling

Jamais `print()` en code prod. Utiliser :
```swift
private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "ModuleName")
Self.logger.error("Message: \(err.localizedDescription)")
```

Jamais `try?` qui mange silencieusement. `do/catch` explicite ou `throws` propagé.

### Commits

Tout commit est authoré par **Quentin Aslan `<contact@quentinaslan.com>`**. Jamais `Claude <noreply@anthropic.com>` en author, jamais `Co-Authored-By: Claude`, aucune mention de Claude / Claude Code dans les messages ou PR descriptions.

Si le harness injecte `Claude` comme author (via `--author=` ou variables d'env), override avant commit ou amend avec `git commit --amend --no-edit --reset-author`. Vérifier après chaque commit avec `git log -1 --pretty=format:"%an <%ae>"`.

**Messages : une seule ligne, explicite, simple.** Format : `type(scope?): verbe à l'impératif objet concret`. Pas de body, pas de liste à puces, pas d'explication du "pourquoi" — ça va dans la PR ou le code. Le scope est optionnel.

Exemples ✓ : `feat: export/import JSON backup (dev-only)` · `fix(editor): only validate segment dots on defocus` · `refactor: drop quick-add bar hidden by keyboard`

Exemples ✗ : `fix(backup): include backDrawing + MainActor + fileImporter single URL\n\n- …\n- …\n- …` (trop long, bullets inutiles) · `chore: update stuff` (vide de sens).

## État MVP + roadmap

MVP livré — itérations post-MVP continues (soft-delete en cascade, learning steps, custom delete sheet, empty states). Prochains chantiers V1.1 : sync Supabase, Sign in with Apple, light theme, stats avancées, modifications TDAH de FSRS (backlog-aware, variabilité).

## Décisions architecturales

Cf dossier `docs/adr/` pour le contexte et les alternatives considérées :

1. [ADR-0001](docs/adr/0001-ios-deployment-target.md) — iOS 18 minimum + iOS 26 progressif
2. [ADR-0002](docs/adr/0002-liquid-glass-chrome-only.md) — Liquid Glass chrome-only via `memoireSurface`
3. [ADR-0003](docs/adr/0003-swiftdata-supabase-deferred.md) — SwiftData local, Supabase V1.1
4. [ADR-0004](docs/adr/0004-draft-struct-editing.md) — Draft struct pour éditer les `@Model`
5. [ADR-0005](docs/adr/0005-swift-fsrs-shortterm.md) — swift-fsrs avec ShortTermScheduler
6. [ADR-0006](docs/adr/0006-apppreferences-vs-usersettings.md) — `AppPreferences` temporaire vs `UserSettings @Model`
7. [ADR-0007](docs/adr/0007-learning-steps.md) — Learning steps app-layer avant graduation FSRS
8. [ADR-0008](docs/adr/0008-home-ux-tdah-pass.md) — Passe UX/TDAH sur l'Accueil (salut dynamique, estimation honnête, streak anti-flicker, garde-fou nuit)

## Documents de référence

Sources de vérité pour toute question produit, design ou scope. À consulter **avant** de proposer une nouvelle feature ou décision.

- **`docs/cahier-des-charges/v1.1.txt`** — CDC complet (2304 lignes). Source unique pour : modèles de données exacts, algo FSRS, learning steps, 10 événements monitoring, freemium (3 decks / 100 cartes), onboarding (4 écrans), principes TDAH, empty states, hors-périmètre V1.1+.
- **`docs/research/liquid-glass-brief.md`** — recherche externe qui a façonné toutes les décisions Liquid Glass : doctrine chrome-only, iOS 18+ progressive, Mode Calme, WCAG AAA 15:1, photophobie TDAH, split gold/goldOnGlass.

## Hors périmètre MVP

Reportés à V1.1+ : Sync Supabase, Sign in with Apple, light theme, import Anki/CSV, images/rich text/cloze/tags, widgets, Watch, modifications TDAH de FSRS, stats avancées, decks partagés.

## Utilisateur

Quentin Aslan (`contact@quentinaslan.com`) — apprend SwiftUI, parle français, préfère qu'on code d'abord et qu'on explique le flux de données après (pas de chapitre théorique en amont).
