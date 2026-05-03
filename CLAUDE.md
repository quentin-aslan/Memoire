# Mémoire

iOS spaced-repetition app (FSRS) tuned for adults with ADHD. "Dark luxury" aesthetic — matte gold `#D4AF37`, New York serif, Liquid Glass on chrome only.

## Stack

- **SwiftUI** — iOS 18.0 deployment target, iOS 26 progressive enhancement for Liquid Glass
- **SwiftData** — local persistence. Sync-ready fields (`isSoftDeleted`, `syncVersion`, `syncStatus`) but **Supabase deferred to V1.1**
- **swift-fsrs** — FSRS v5 spaced-repetition algorithm (SPM package, `ShortTermScheduler`)
- **Xcode 26+ / Swift 5** — built against the iOS 26 SDK

## Build commands

**⚠️ Important** — Xcode's default destination may be a physical iPhone (signing required). To build without a Team:

```bash
cd "/Users/quentinaslan/DEV/Mémoire"
scheme=$(xcodebuild -list 2>/dev/null | awk '/Schemes:/{found=1; next} found && NF{gsub(/^ +| +$/, "", $0); print; exit}')
xcodebuild -project "Memoire.xcodeproj" -scheme "$scheme" -destination 'generic/platform=iOS Simulator' build
```

Note: only the **repo folder** is spelled `Mémoire` with an accent — the `.xcodeproj`, target, and scheme are all spelled `Memoire` (no accent). The `awk` above just trims spaces from `xcodebuild -list` output.

If the Xcode MCP is connected (`mcp__xcode__BuildProject`): it uses Xcode's active destination → fails if a physical iPhone is selected without a Team.

## Structure

```
Memoire/
  MemoireApp.swift           @main entry + ModelContainer + UIKit Appearance + env injection
  ContentView.swift          delegates to RootView
  RootView.swift             TabView + onboarding/tabs branching + toolbarBackground for calmMode
  AppPreferences.swift       @Observable, UserDefaults-backed (UI-only prefs)
  AppRoute.swift             Hashable enum for type-safe nav
  DeckCreationCoordinator.swift  coordinates deck creation flow between Home and Decks

  Color+Tokens.swift         palette (init(hex:) + semantic tokens)
  Typography.swift           Font.serif/.sans + named styles
  GlassSurface.swift         .memoireSurface modifier (single Liquid Glass entry point)
  ProgressRing.swift         reusable ring component
  PrimaryButton.swift        shared PrimaryButtonStyle (gold gradient)

  HomeScreen.swift           Home (ring + regularity + CTA)
  DecksScreen.swift          deck list (+ reorder + swipe delete + "+" create)
  DeckDetailScreen.swift     deck detail (card list + "+" create)
  CardDetailScreen.swift     card detail (MEMORIZATION section: state, difficulty, stability)
  ReviewScreen.swift         review session (3D flip + ratings)
  ReviewSession.swift        @Observable transient session state (re-queue .again)
  CompleteScreen.swift       end-of-session
  Rating.swift               3-case enum: .again / .good / .easy → "À revoir / Moyen / Facile"
  OnboardingFlow.swift       6 pages with sensitivity + reminder
  SettingsScreen.swift       Form (Calm Mode, notif, cards/day, Report a bug)
  EmptyDecksState.swift      empty state for deck list (CTA + illustration)
  EmptyDueState.swift        "up to date" empty state (with "come back later" variant)

  Models/                    SwiftData @Model classes
    Deck.swift
    Card.swift               includes `learningStep: Int` (step before FSRS graduation)
    Review.swift
    SyncStatus.swift         Int enum (synced/pendingCreate/pendingUpdate/pendingDelete)

  AppConstants.swift         shared constants (Logger subsystem, notification ID prefix, FSRS bounds, LearningSteps.steps…)

  Scheduling/                FSRS algorithm
    FSRSState.swift          enum FSRSState (new/learning/review/relearning) — call-site abstraction
    FSRSScheduler.swift      ShortTermScheduler wrapper
    CardFSRSAdapter.swift    Card ↔ SwiftFSRS.Card snapshot + Rating → SwiftFSRS.Rating
    DailyQueue.swift         daily queue (due non-new + capped new)
    SchedulerMigration.swift one-shot FSRS migration on first launch

  Features/
    DeleteConfirmationSheet.swift   modal delete confirmation sheet (cascade deck → cards)
    Editor/                         deck/card CRUD
      DeckDraft.swift
      CardDraft.swift
      DeckEditorSheet.swift    modal sheet for deck create/edit
      CardEditorSheet.swift    modal sheet with "Save and add another"
      EditorError.swift

  Services/
    NotificationScheduler.swift  daily notifications
    RegularityCalculator.swift   regularity score (rolling 30 days)

docs/adr/                    documented architecture decisions
```

## Hard conventions

### Code in English

All identifiers (variables, functions, types, enums, comments) are in English.

**Exception**: user-facing strings (`Text()`, `.accessibilityLabel()`, `.navigationTitle()`, placeholders) stay in French — it's a French app.

Comments explain the **WHY**, never the WHAT. A comment that reads like the code itself must be removed.

### No magic numbers or strings

Any value with business meaning or shared across multiple files must live in a named constant.

**`AppConstants.swift`** — single source for:
- `AppConstants.Logging.subsystem` → replaces `"com.memoire.app"` everywhere
- `AppConstants.Notifications.dailyReviewIDPrefix`
- `AppConstants.FSRS.defaultRetention / minRetention / maxRetention`
- `AppConstants.FSRS.easyDifficultyThreshold / mediumDifficultyThreshold`
- `AppConstants.Regularity.windowDays`
- `AppConstants.Onboarding.pageCount`

**`Color+Tokens.swift`** — `Color.goldHex` is the single source for the `"#D4AF37"` value used as default color string.

**`Scheduling/FSRSState.swift`** — `enum FSRSState: Int` abstracts `Card.fsrsState`'s raw `0/1/2/3` Ints at call sites. SwiftData storage stays `Int` to avoid a schema migration.

**Documented exceptions**: one-off SwiftUI paddings (`.padding(20)`), animation durations, corner radii — don't extract if not shared across files.

### Glass chrome-only

**Single Liquid Glass entry point**: `.memoireSurface(in:tint:interactive:)` in `GlassSurface.swift`. Automatically respects `accessibilityReduceTransparency`, `prefs.calmMode`, and iOS 26 availability.

**Calm Mode disables ALL glass**: in addition to `memoireSurface`, the tab bar's glass is controlled via `.toolbarBackground(prefs.calmMode ? Color.bgPrimary : .clear, for: .tabBar)` in `RootView`. Any new glass added must also respect `prefs.calmMode`.

Forbidden:
- direct `.glassEffect()` (bypasses the fallback + chrome-only doctrine)
- `.glassEffect(.clear)` (banned by the brief)
- glass on **editorial content** (review card, lists, long text). Anything carrying New York type sits on a **solid** surface (`surfaceElevated` or `surfaceRaised`).

Glass only on: tab bar (auto on iOS 26), toolbars, sheets, paywall CTA, FSRS rating buttons.

### No magic strings

Any string used as an identifier (UserDefaults key, notification name, predicate, analytics event) must live in a named `enum` or `static let` — never inline. See also **No magic numbers or strings** above.

```swift
// ✗
UserDefaults.standard.bool(forKey: "prefs.calmMode")
// ✓
UserDefaults.standard.bool(forKey: Keys.calmMode)  // Keys is a private enum in AppPreferences
```

### Review session — re-queue "Again"

`ReviewSession.rate()` re-appends the card to the end of `cards` on every `.again` rating. No cap. The card returns until rated "Good" or "Easy" — standard FSRS/Anki behavior. `totalCount` grows dynamically; that's not a bug.

### Learning steps before FSRS

New cards + relearning cards go through **fixed steps** (`AppConstants.LearningSteps.steps`) before entering `.review` driven by FSRS. The current step lives in `Card.learningStep: Int` (0 = first step, -1 = graduated). `ReviewSession.rate()` intercepts the rating before delegating to the scheduler. See [ADR-0007](docs/adr/0007-learning-steps.md).

### Design tokens

No hex colors hardcoded in views. Use `Color.bgPrimary`, `Color.gold`, `Color.goldTint`, etc. from `Color+Tokens.swift`.

No hardcoded `.system(size:)`. Use `Font.serif(_:)`, `Font.sans(_:)`, or named styles (`.uiButton`, `.cardQuestion`, …) from `Typography.swift`.

### UIKit Appearance

Every global UIKit override (nav bar, table view cells) is centralized in `MemoireApp.init()`. Don't call `UINavigationBar.appearance()` or `UITableViewCell.appearance()` anywhere else. `UIWindow.appearance().overrideUserInterfaceStyle` is a no-op (not a `UI_APPEARANCE_SELECTOR`) — don't use it.

### SwiftData editing

For any editing UI: use a value-type **draft struct** (`DeckDraft`, `CardDraft`), never `@Bindable` directly on a `@Model`. The commit happens only on explicit Save. See [ADR-0004](docs/adr/0004-draft-struct-editing.md).

### Soft delete

Never `context.delete(model)`. Always:
```swift
deck.isSoftDeleted = true
deck.deletedAt = .now
deck.syncVersion += 1
deck.syncStatus = SyncStatus.pendingDelete.rawValue
```
Filter in views via `.filter { !$0.isSoftDeleted }` or a SwiftData predicate. Note: the field is named `isSoftDeleted` (not `isDeleted`) to avoid shadowing `PersistentModel.isDeleted` from SwiftData — shadowing that prevented the flag from persisting.

### Environment

`AppPreferences` is reachable everywhere via `@Environment(\.appPreferences)` (`@Entry` pattern, default `.shared` so previews never crash). Production injection happens in `MemoireApp`.

### Error handling

Never `print()` in production code. Use:
```swift
private static let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: "ModuleName")
Self.logger.error("Message: \(err.localizedDescription)")
```

Never `try?` that silently swallows. Use explicit `do/catch` or propagate `throws`.

### Internationalization

Source-as-key in `Memoire/Resources/Localizable.xcstrings`. Source = `fr`, second locale = `en`.

- SwiftUI views: `Text("Bonjour")` directly (Xcode auto-extracts).
- Non-Text (notifications, enums, `AttributedString` segments, dynamic accessibility labels): `String(localized: "…")` or `LocalizedStringResource`.
- Plurals: CLDR `one`/`other` in the catalog. Never `count == 1 ? "carte" : "cartes"` in code.
- Dates: `date.formatted(.dateTime…)` (follows `Locale.current`). Forbidden: `DateFormatter` with hardcoded `Locale("fr_FR")`.
- EditorialSheet footnotes: « En anglais : Stability/Retrievability » → inverted in EN as « In French: Solidité/Fraîcheur ».

**Single source of truth for EN translations: `scripts/sync-xcstrings.py`.** Never edit `Localizable.xcstrings` by hand to add EN — always go through the script.

**Before any commit or push that touches a user-facing string** (`Text("…")`, `String(localized: "…")`, `LocalizedStringResource(…)`, accessibility label, notification, widget copy):

```bash
python3 scripts/sync-xcstrings.py
```

Must show `Missing: 0`, exit code `0`. If `Missing > 0`: add the missing FR → EN pairs to `TRANSLATIONS` or `PLURALS` in the script, re-run, then commit. See `scripts/README.md`.

### Copy & thresholds — sync with `docs/v4-copy-and-algorithms.md`

Any frozen user-facing string (status words, insight sentences, sheets, onboarding, toast, completion registers, deck headlines, etc.) **and** any algorithmic threshold/rule (status resolution, stability bands, formatDuration, toast conditions, weighted draws) is indexed in `docs/v4-copy-and-algorithms.md`.

Whenever a copy or threshold changes in code:
- **Mirror the change in the doc** (same phrase, same rule).
- If you add a new copy/rule, **extend the doc** rather than letting it float in code only.
- At the end of a feature, verify the doc reflects the code state — it's the source of truth for future refactors.

### Commits

Every commit is authored by **Quentin Aslan `<contact@quentinaslan.com>`**. Never `Claude <noreply@anthropic.com>` as author, never `Co-Authored-By: Claude`, no mention of Claude / Claude Code in messages or PR descriptions.

If the harness injects `Claude` as author (via `--author=` or env vars), override before committing or amend with `git commit --amend --no-edit --reset-author`. Verify after every commit with `git log -1 --pretty=format:"%an <%ae>"`.

**Messages: single line, explicit, simple.** Format: `type(scope?): imperative verb concrete object`. No body, no bullet list, no "why" explanation — that goes in the PR or the code. Scope is optional.

Examples ✓: `feat: export/import JSON backup (dev-only)` · `fix(editor): only validate segment dots on defocus` · `refactor: drop quick-add bar hidden by keyboard`

Examples ✗: `fix(backup): include backDrawing + MainActor + fileImporter single URL\n\n- …\n- …\n- …` (too long, useless bullets) · `chore: update stuff` (meaningless).

## MVP status & roadmap

MVP shipped — post-MVP iterations ongoing (cascading soft-delete, learning steps, custom delete sheet, empty states). Next V1.1 work: Supabase sync, Sign in with Apple, light theme, advanced stats, ADHD-aware FSRS tweaks (backlog-aware, variability).

## Architecture decisions

See `docs/adr/` for context and considered alternatives:

1. [ADR-0001](docs/adr/0001-ios-deployment-target.md) — iOS 18 minimum + iOS 26 progressive
2. [ADR-0002](docs/adr/0002-liquid-glass-chrome-only.md) — Liquid Glass chrome-only via `memoireSurface`
3. [ADR-0003](docs/adr/0003-swiftdata-supabase-deferred.md) — SwiftData local, Supabase V1.1
4. [ADR-0004](docs/adr/0004-draft-struct-editing.md) — Draft struct for editing `@Model`s
5. [ADR-0005](docs/adr/0005-swift-fsrs-shortterm.md) — swift-fsrs with ShortTermScheduler
6. [ADR-0006](docs/adr/0006-apppreferences-vs-usersettings.md) — `AppPreferences` (temporary) vs `UserSettings @Model`
7. [ADR-0007](docs/adr/0007-learning-steps.md) — App-layer learning steps before FSRS graduation
8. [ADR-0008](docs/adr/0008-home-ux-tdah-pass.md) — ADHD UX pass on Home (dynamic greeting, honest estimate, anti-flicker streak, night safeguard)

## Reference documents

Sources of truth for any product, design, or scope question. Read **before** proposing a new feature or decision.

- **`docs/cahier-des-charges/v1.1.txt`** — full spec (2304 lines). Single source for: exact data models, FSRS algorithm, learning steps, 10 monitoring events, freemium (3 decks / 100 cards), onboarding (4 screens), ADHD principles, empty states, V1.1+ out-of-scope items.
- **`docs/research/liquid-glass-brief.md`** — external research that shaped every Liquid Glass decision: chrome-only doctrine, iOS 18+ progressive, Calm Mode, WCAG AAA 15:1, ADHD photophobia, gold/goldOnGlass split.

## Out of MVP scope

Deferred to V1.1+: Supabase sync, Sign in with Apple, light theme, Anki/CSV import, images/rich text/cloze/tags, widgets, Watch, ADHD-aware FSRS, advanced stats, shared decks.

## User

Quentin Aslan (`contact@quentinaslan.com`) — learning SwiftUI, French speaker, prefers code-first then data-flow explanation after (no theory chapter upfront).
