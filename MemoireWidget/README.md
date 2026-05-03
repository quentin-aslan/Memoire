# MemoireWidget

A systemSmall widget that surfaces today's review state on the home screen. Reads the SwiftData store via an App Group shared with the main app — no duplicated database.

---

## What it shows

The widget renders one of four states based on the daily queue:

| State | View | When |
|---|---|---|
| A — **Due** | `States/DueNowView.swift` | Cards due now → counter |
| B — **Up to date** | `States/UpToDateView.swift` | No cards due → encouragement message |
| C — **Later** | `States/LaterTodayView.swift` | Cards due later today → time (e.g. `14h30`) |
| D — **Onboarding** | `States/OnboardingView.swift` | App never launched, or snapshot stale > 24 h |

The state is computed in the main app (`Shared/WidgetSnapshot.swift`), serialized into the shared store. The widget only reads and renders.

---

## Architecture

- **App Group** `group.com.quentinaslan.Memoire` shares the SwiftData `ModelContainer` between app and widget.
- **Refresh** only on `.background` transitions (not `.inactive`) to avoid ghost refreshes — see commit `23f49e5`.
- **Predicate pushdown + schema guard** in `MemoireWidgetProvider.swift`: the widget tolerates a desynced schema without crashing (commit `ab27c40`).
- **Deep-link**: tapping the widget → `RootView.handleDeepLink` opens the right screen via `WidgetLaunchCoordinator` on the app side.
- **Files shared between targets**: `AppConstants.swift`, `Color+Tokens.swift`, `Typography.swift`, `Shared/WidgetSnapshot.swift`.

---

## Build and test

```bash
# Build the widget alone
xcodebuild -project Memoire.xcodeproj -scheme MemoireWidget \
  -destination 'generic/platform=iOS Simulator' build
```

On Simulator:

1. Launch the app at least once (otherwise no snapshot exists → state D).
2. Sim home screen → long-press → **+** → search **Mémoire** → Add Widget.
3. Verify all 4 states:
   - **D** — fresh install or stale > 24 h.
   - **A** — create 1 deck + 3 cards, return to home → widget reads `3`.
   - **B** — finish the review session → widget shows "Up to date".
   - **C** — advance the sim clock so a card becomes due later today → widget shows `14h30`.

---

## Xcode setup (one-time, Mac only)

The Swift sources, `Info.plist`, and `.entitlements` are already committed. **6 GUI steps in Xcode** remain (manual editing of `.pbxproj` in `objectVersion = 77` format with `PBXFileSystemSynchronizedRootGroup` is too brittle to script).

### 1. Create the target

Xcode > **File > New > Target…** > **Widget Extension**.

- Product Name: **`MemoireWidget`** (exact, no accent)
- Bundle Identifier: auto (`com.quentinaslan.Memoire.MemoireWidget`)
- Include Configuration Intent: **off** (we use `StaticConfiguration`)
- Include Live Activity: **off**
- Embed in Application: **Memoire** (selected by default)

Click **Finish**. If Xcode offers to activate the scheme, accept.

### 2. Delete the Xcode-generated files

Xcode auto-creates:
- `MemoireWidget/MemoireWidget.swift`
- `MemoireWidget/MemoireWidgetBundle.swift`
- `MemoireWidget/AppIntent.swift` (if accidentally checked)

**Delete these 3 files** (Move to Trash) — our pre-written versions replace them.

Keep:
- `MemoireWidget/Info.plist` auto-generated → replace with the one in the repo (already committed), or leave it as long as it references `widgetkit-extension`.
- `MemoireWidget.entitlements` auto-generated → replace with the one in the repo.
- `Assets.xcassets` for the widget → leave it (empty for now).

### 3. Import our files into the target

In the **Project Navigator**, drag-and-drop the repo's `MemoireWidget/` folder into the project's `MemoireWidget` group.

In the *Choose options* dialog: check **Add to targets > MemoireWidget** only (not the app).

Verify in the navigator that all `.swift` files are listed:
```
MemoireWidget/
  MemoireWidgetBundle.swift
  MemoireWidget.swift
  MemoireWidgetProvider.swift
  MemoireWidgetEntry.swift
  MemoireWidgetEntryView.swift
  WidgetChrome.swift
  States/
    DueNowView.swift
    UpToDateView.swift
    LaterTodayView.swift
    OnboardingView.swift
```

### 4. Share the common files with the widget

Select these 4 files in `Memoire/` (already members of the app target):

- `Memoire/AppConstants.swift`
- `Memoire/Color+Tokens.swift`
- `Memoire/Typography.swift`
- `Memoire/Shared/WidgetSnapshot.swift`

For each → open the **File Inspector** (right panel) → **Target Membership** → check **MemoireWidget** alongside **Memoire**.

### 5. App Group on both targets

For **each** target (`Memoire` and `MemoireWidget`):

- **Signing & Capabilities** tab.
- **+ Capability > App Groups**.
- Check / create the group: **`group.com.quentinaslan.Memoire`**.

Verify the target's `.entitlements` points to our file (it should — Xcode auto-references it).

### 6. Verify deployment target

- Target `MemoireWidget` > **General** > **Deployment Info** > **Minimum Deployments** = **iOS 18.0**.
- Same for the widget scheme if Xcode created a separate one.

---

## Troubleshooting

- **Widget doesn't appear in the gallery**: verify the `MemoireWidget` scheme builds without errors, and that `Info.plist` contains `NSExtensionPointIdentifier = com.apple.widgetkit-extension`.
- **"No content"** on the widget: the app has never run → snapshot missing → state D shows, expected. Launch the app.
- **Widget doesn't refresh after a review**: verify both targets share the same `group.com.quentinaslan.Memoire` in Signing & Capabilities.
- **Crash on deep-link tap**: verify `RootView.handleDeepLink` is wired — there's an `.onOpenURL` in `RootView.swift`.
