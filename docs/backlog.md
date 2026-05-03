# Backlog

Living document tracking work that is **deliberately deferred** or **in standby**. The goal: avoid losing intent when a decision is made to "do it later", and avoid littering issues across CLAUDE.md, the cahier des charges, and the roadmap.

Update at the end of any feature where a deferral was made. When an item ships, replace its entry with a link to the commit, ADR, or spec section that landed it.

---

## Standby — to do later

- **Automated test suite** — no XCTest target yet. Priority targets when it lands: `ReviewSession.applyLearningStep` matrix (covering `.again` reset / `.good` step advance / `.easy` graduation), `CardFSRSAdapter` round-trip (Card ↔ SwiftFSRS.Card), `DailyQueue.build` queue ordering and new-card cap, `RegularityCalculator` rolling-30d boundary.
- **README screenshots / GIF** — Home (ProgressRing + greeting + CTA), Review (3D flip + 3 rating buttons), Calm Mode (no glass), `MemoireWidget` (4 states). The pitch sells "dark luxury" but the README shows nothing visual.

---

## Conventions

- Add an item: short title + 1–2 sentences explaining the **what** and the **why deferred**.
- Move an item out: replace with a link to the commit, ADR, or spec section that landed it. Don't delete — keep traceability.
- One bullet per item. Keep the file scannable.
- High-level deferrals (full V1.1 features like Supabase sync, Apple Watch) live in `CLAUDE.md` "Out of MVP scope" and `docs/cahier-des-charges/v1.1.txt`. This file is for **smaller, in-flight standby items** between releases.
