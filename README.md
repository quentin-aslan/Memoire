# Mémoire

**iOS spaced-repetition app, designed for adults with ADHD.**

Mémoire helps you remember what actually matters — with a science-backed algorithm, a frictionless interface, and a design built for brains that bore quickly.

---

## What the app does

You create **decks of cards** (vocabulary, formulas, concepts, etc.). Every day, Mémoire shows you only the cards you *need* to review that day — no more, no less.

After flipping a card, you rate your memory:

- **Again** (`À revoir`) — you didn't get it at all
- **Good** (`Moyen`) — it came back, but with effort
- **Easy** (`Facile`) — instantly

The algorithm adjusts the next review date for each card automatically. The better you rate, the further out the card goes. The more you miss, the sooner it returns.

---

## Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 18+, iOS 26 progressive) |
| Persistence | SwiftData (local) |
| Algorithm | FSRS v5 via `swift-fsrs` (SPM) |
| Widget | WidgetKit (target `MemoireWidget`, shared App Group) |
| Language | Swift 5 |
| Minimum target | iOS 18.0 |
| Build | Xcode 26+ / iOS 26 SDK |

---

## The FSRS algorithm

FSRS (**Free Spaced Repetition Scheduler**) is the most advanced open-source spaced-repetition algorithm available today. It was born as an alternative to the SM-2 algorithm Anki has used for 30 years.

**How it works**

Each card has two key parameters:
- **Stability** (S) — how many days the memory holds without review
- **Difficulty** (D) — how hard the card is to memorize

After each review, FSRS recomputes both values and schedules the next review at the precise moment your recall probability drops below the configured retention target (90% by default).

**What this means in practice:**
- An easy card can move out to 30, 90, 365 days
- A hard card returns in 1–3 days until consolidated
- Failed cards (`.again`) are re-queued in the same session until learned

**Integration in Mémoire:**
- Package `4rays/swift-fsrs` (FSRS v5)
- **Learning steps** `[10 min → 1 h → 1 d]` handled in `ReviewSession` before graduation to Review — FSRS is only invoked at graduation (see `Scheduling/`)
- Daily queue: overdue cards first, then new cards (configurable cap, 10/day by default)

---

## Design

**Dark luxury** aesthetic:
- Near-black background `#1C1C1E`
- Matte gold `#D4AF37` as the primary accent
- **New York** (Apple's serif) for memorization content
- **Liquid Glass** on chrome only (tab bar, rating buttons) — never on text

**Calm Mode** disables every visual effect (glass, animations) for users sensitive to light or in sensory overload — a common case among adults with ADHD.

---

## Project structure

```
Memoire/
├── Memoire/                    Main app target
│   ├── MemoireApp.swift        @main + ModelContainer + env injection
│   ├── RootView.swift          TabView + onboarding + deep-links
│   ├── *Screen.swift           Views (Home, Decks, DeckDetail, CardDetail, Review, Complete, Settings)
│   ├── OnboardingFlow.swift    4 onboarding pages
│   ├── AppConstants.swift      Single source of truth for constants (logging, FSRS, regularity…)
│   ├── AppPreferences.swift    @Observable, UserDefaults-backed
│   ├── Color+Tokens.swift      Palette and design tokens
│   ├── Typography.swift        Type system (New York + sans)
│   ├── GlassSurface.swift      Single entry point for Liquid Glass
│   ├── ReviewSession.swift     Transient state (re-queue .again, learning steps)
│   ├── Models/                 SwiftData @Model (Deck, Card, Review, SyncStatus)
│   ├── Scheduling/             FSRS algorithm (wrapper, adapter, queue, migration)
│   ├── Features/Editor/        Drafts + create/edit sheets
│   ├── Sheets/                 EditorialSheet, DeckStatsSheet
│   ├── Shared/                 WidgetSnapshot, DurationFormat, CompositionBar
│   ├── Services/               Notifications, RegularityCalculator
│   └── Resources/              Localizable.xcstrings (FR + EN)
├── MemoireWidget/              Widget extension target (see its own README)
├── docs/                       ADRs, v1.1 spec, research, copy reference
├── scripts/                    sync-xcstrings.py
├── CLAUDE.md                   Code & commit conventions
└── README.md
```

---

## Prerequisites

- macOS 14.0+ (Sequoia or later recommended)
- Xcode 26.0+ with the iOS 26 SDK
- iOS 18.0+ Simulator runtime
- `swift-fsrs` is auto-resolved by Xcode via Swift Package Manager — no manual setup

---

## Build & run

> ⚠️ **Naming gotcha** — the **repo folder** is `Mémoire` (with accent), but the `.xcodeproj`, target, and scheme are all spelled `Memoire` (no accent). Don't mix them up.

```bash
# App build (simulator, no signing)
xcodebuild -project Memoire.xcodeproj -scheme Memoire \
  -destination 'generic/platform=iOS Simulator' build

# Widget build
xcodebuild -project Memoire.xcodeproj -scheme MemoireWidget \
  -destination 'generic/platform=iOS Simulator' build
```

⚠️ Xcode's default destination may be a physical iPhone (signing required). Force the simulator with `-destination` as shown to build without a Team.

---

## Run on a physical iPhone

1. Open `Memoire.xcodeproj` → select the `Memoire` target → **Signing & Capabilities** → check **Automatically manage signing** → pick your personal Apple Team.
2. Repeat for the `MemoireWidget` target. **Both targets must share the App Group** `group.com.quentinaslan.Memoire` (already wired in the `.entitlements` files).
3. Connect the iPhone, select it as destination, hit **Run**.
4. First launch may require trusting the developer certificate on the device: Settings → General → VPN & Device Management.

---

## Internationalization (FR + EN)

The app is bilingual (FR source, EN secondary) via Apple String Catalogs (`Memoire/Resources/Localizable.xcstrings`). Source-as-key: a string's key *is* its French phrase.

Whenever you add a user-facing string, update `scripts/sync-xcstrings.py` and run it to propagate FR → EN and CLDR plural rules into the catalog. See `scripts/README.md` for the full procedure.

---

## Features

### MVP (v1.0)
- [x] 4-screen onboarding (interactive flip demo, Calm Mode, notifications)
- [x] Deck and card CRUD
- [x] Review session with animated 3D flip
- [x] FSRS v5 algorithm integration
- [x] Smart daily queue (due + new)
- [x] Regularity score (rolling 30 days)
- [x] Calm Mode (accessibility, photophobia)
- [x] Configurable daily notifications
- [x] Card detail: FSRS state, difficulty, stability, history
- [x] Soft delete (sync-ready)
- [x] Accessibility: VoiceOver, Reduce Motion, Reduce Transparency

### Post-MVP shipped
- [x] English locale via String Catalog + FR → EN sync script
- [x] systemSmall widget (4 states: due / later / up-to-date / onboarding)
- [x] JSON backup export/import (dev-only, accessible from Settings)
- [x] Drawing on the card back (Apple Pencil + finger)
- [x] Onboarding NamePage with personalized first name
- [x] ADHD UX pass on Home (ADR-0008)
- [x] Custom delete sheet with cascading soft-delete

---

## Roadmap (V1.1+)

- Supabase sync + Sign in with Apple
- Light theme
- Anki / CSV import
- Apple Watch
- Advanced stats
- ADHD-aware FSRS tweaks (variability, backlog-aware)

Smaller in-flight items deliberately deferred are tracked in [`docs/backlog.md`](docs/backlog.md).

---

## Documentation

| File | Audience |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | Code, build, commit, i18n conventions — read before contributing |
| [`docs/adr/`](docs/adr/) | 8 architecture decisions (iOS 18+, Liquid Glass, SwiftData, learning steps, etc.) |
| [`docs/cahier-des-charges/v1.1.txt`](docs/cahier-des-charges/v1.1.txt) | Full product spec (data models, FSRS config, freemium, monitoring events) |
| [`docs/research/liquid-glass-brief.md`](docs/research/liquid-glass-brief.md) | External research that shaped the Liquid Glass doctrine |
| [`docs/v4-copy-and-algorithms.md`](docs/v4-copy-and-algorithms.md) | Source of truth for frozen copy + algorithmic thresholds |
| [`docs/backlog.md`](docs/backlog.md) | Items deliberately deferred or in standby |
| [`MemoireWidget/README.md`](MemoireWidget/README.md) | Widget architecture + Xcode setup |

---

## Engineering highlights

A short tour of the more substantive choices — see [`docs/adr/`](docs/adr/) for full context, considered alternatives, and consequences.

- **Single Liquid Glass entry point** — the `.memoireSurface` modifier respects `accessibilityReduceTransparency`, Calm Mode, and iOS 26 availability automatically. Editorial content (cards, lists, long text) is forbidden from glass to preserve WCAG AAA contrast. See [ADR-0002](docs/adr/0002-liquid-glass-chrome-only.md).
- **App-layer learning steps before FSRS graduation** — `ReviewSession` intercepts `.again` / `.good` ratings and applies fixed steps `[10 min → 1 h → 1 d]` before delegating to FSRS. The `swift-fsrs` package stays untouched. See [ADR-0007](docs/adr/0007-learning-steps.md).
- **Draft-struct editing pattern** — value-type `DeckDraft` / `CardDraft`, never `@Bindable` directly on a `@Model`. The commit happens only on explicit Save. See [ADR-0004](docs/adr/0004-draft-struct-editing.md).
- **Sync-ready soft-delete** — every model carries `isSoftDeleted`, `deletedAt`, `syncVersion`, `syncStatus`. The schema is V1.1-ready before Supabase lands. See [ADR-0003](docs/adr/0003-swiftdata-supabase-deferred.md).
- **Bilingual via Apple String Catalogs** — FR source, EN script-synced via `python3 scripts/sync-xcstrings.py`. `Localizable.xcstrings` is never edited by hand; CLDR plural rules live in the catalog.
- **ADHD-aware UX** — VoiceOver labels on every interactive element, Reduce Motion via custom flip override, Reduce Transparency hardening, photophobia-aware Calm Mode, anti-flicker streak. See [ADR-0008](docs/adr/0008-home-ux-tdah-pass.md).

---

## Status & license

This is a **personal portfolio project**, not open source. The source is publicly visible for reference only — **no license is granted** for use, copying, modification, or redistribution. Issues and pull requests from outside contributors are not accepted at this time. To discuss any use of the code, contact me directly via email.

The app is **not yet published** — no TestFlight or App Store link yet.

---

## Author

Quentin Aslan — [contact@quentinaslan.com](mailto:contact@quentinaslan.com)
