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

## Build & run

The repo folder is spelled `Mémoire` (with accent) — but the `.xcodeproj`, target, and scheme are all spelled `Memoire` (no accent).

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

### V2

- Web (Vue.js PWA) sharing the Supabase backend

---

## Documentation

| File | Audience |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | Code, build, commit, i18n conventions — read before contributing |
| [`docs/adr/`](docs/adr/) | 8 architecture decisions (iOS 18+, Liquid Glass, SwiftData, learning steps, etc.) |
| [`docs/cahier-des-charges/v1.1.txt`](docs/cahier-des-charges/v1.1.txt) | Full product spec (data models, FSRS config, freemium, monitoring events) |
| [`docs/research/liquid-glass-brief.md`](docs/research/liquid-glass-brief.md) | External research that shaped the Liquid Glass doctrine |
| [`docs/v4-copy-and-algorithms.md`](docs/v4-copy-and-algorithms.md) | Source of truth for frozen copy + algorithmic thresholds |
| [`MemoireWidget/README.md`](MemoireWidget/README.md) | Widget architecture + Xcode setup |

---

## Author

Quentin Aslan — [contact@quentinaslan.com](mailto:contact@quentinaslan.com)
