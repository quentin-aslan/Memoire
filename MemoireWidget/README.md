# MemoireWidget

Widget systemSmall qui affiche l'état des révisions du jour sur l'écran d'accueil. Lit la base SwiftData via un App Group partagé avec l'app principale, sans dupliquer le store.

---

## Ce qu'il affiche

Le widget rend l'un de quatre états selon l'état de la file quotidienne :

| État | Vue | Quand |
|---|---|---|
| A — **À faire** | `States/DueNowView.swift` | Cartes dues maintenant → compteur |
| B — **À jour** | `States/UpToDateView.swift` | Aucune carte due → message d'encouragement |
| C — **Plus tard** | `States/LaterTodayView.swift` | Cartes dues plus tard dans la journée → heure (ex. `14h30`) |
| D — **Onboarding** | `States/OnboardingView.swift` | App jamais lancée ou snapshot stale > 24 h |

L'état est calculé côté app principale (`Shared/WidgetSnapshot.swift`) puis sérialisé dans le store partagé. Le widget ne fait que lire et rendre.

---

## Architecture

- **App Group** `group.com.quentinaslan.Memoire` partage le `ModelContainer` SwiftData entre l'app et le widget.
- **Refresh** uniquement à la transition `.background` (pas `.inactive`) pour éviter les rafraîchissements fantômes — cf. commit `23f49e5`.
- **Predicate pushdown + schema guard** dans `MemoireWidgetProvider.swift` : le widget tolère un schéma désynchronisé sans crasher (commit `ab27c40`).
- **Deep-link** : tap sur le widget → `RootView.handleDeepLink` ouvre l'écran approprié via `WidgetLaunchCoordinator` côté app.
- **Fichiers partagés** entre les deux targets : `AppConstants.swift`, `Color+Tokens.swift`, `Typography.swift`, `Shared/WidgetSnapshot.swift`.

---

## Build et test

```bash
# Build du widget seul
xcodebuild -project Memoire.xcodeproj -scheme MemoireWidget \
  -destination 'generic/platform=iOS Simulator' build
```

Sur Simulator :

1. Lancer l'app au moins une fois (sinon le snapshot n'existe pas → état D).
2. Home screen sim → long-press → **+** → rechercher **Mémoire** → Add Widget.
3. Vérifier les 4 états :
   - **D** — fresh install ou stale > 24 h.
   - **A** — créer 1 deck + 3 cartes, repli sur home → widget `3`.
   - **B** — terminer la session de review → widget « À jour ».
   - **C** — avancer l'horloge sim pour qu'une carte devienne due dans la journée → widget `14h30`.

---

## Setup Xcode (à faire une seule fois sur Mac)

Les sources Swift, l'`Info.plist` et l'`.entitlements` sont déjà commités. Il reste **6 étapes en GUI Xcode** (l'édition manuelle du `.pbxproj` au format `objectVersion = 77` avec `PBXFileSystemSynchronizedRootGroup` est trop fragile pour être scriptée).

### 1. Créer le target

Xcode > **File > New > Target…** > **Widget Extension**.

- Product Name : **`MemoireWidget`** (exact, sans accent)
- Bundle Identifier : auto (`com.quentinaslan.Memoire.MemoireWidget`)
- Include Configuration Intent : **désactivé** (on utilise `StaticConfiguration`)
- Include Live Activity : **désactivé**
- Embed in Application : **Memoire** (sélectionné par défaut)

Clic **Finish**. Si Xcode propose d'activer le scheme, accepter.

### 2. Supprimer les fichiers Xcode-générés

Xcode crée automatiquement :
- `MemoireWidget/MemoireWidget.swift`
- `MemoireWidget/MemoireWidgetBundle.swift`
- `MemoireWidget/AppIntent.swift` (si jamais coché)

**Supprimer ces 3 fichiers** (Move to Trash) — nos versions pré-écrites les remplacent.

Garder :
- `MemoireWidget/Info.plist` auto-généré → remplacer par celui du repo (déjà commité), ou le laisser en place tant qu'il référence `widgetkit-extension`.
- `MemoireWidget.entitlements` auto-généré → remplacer par celui du repo.
- `Assets.xcassets` du widget → laisser tel quel (vide pour l'instant).

### 3. Importer nos fichiers dans le target

Dans le **Project Navigator**, glisser/déposer le dossier `MemoireWidget/` du repo dans le groupe `MemoireWidget` du projet.

À la dialog *Choose options* : cocher **Add to targets > MemoireWidget** uniquement (pas l'app).

Vérifier dans le navigateur que tous les `.swift` sont bien listés :
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

### 4. Partager les fichiers communs avec le widget

Sélectionner ces 4 fichiers dans `Memoire/` (déjà membres du target app) :

- `Memoire/AppConstants.swift`
- `Memoire/Color+Tokens.swift`
- `Memoire/Typography.swift`
- `Memoire/Shared/WidgetSnapshot.swift`

Pour chacun → ouvrir le **File Inspector** (panneau de droite) → section **Target Membership** → cocher **MemoireWidget** en plus de **Memoire**.

### 5. App Group sur les deux targets

Pour **chaque** target (`Memoire` et `MemoireWidget`) :

- Onglet **Signing & Capabilities**.
- **+ Capability > App Groups**.
- Cocher / créer le groupe : **`group.com.quentinaslan.Memoire`**.

Vérifier que l'`.entitlements` du target pointe bien vers notre fichier (il devrait — Xcode l'auto-référence).

### 6. Vérifier le deployment target

- Target `MemoireWidget` > **General** > **Deployment Info** > **Minimum Deployments** = **iOS 18.0**.
- Idem pour le scheme du widget si Xcode a créé un scheme séparé.

---

## Troubleshooting

- **Widget ne s'affiche pas dans la galerie** : vérifier que le scheme `MemoireWidget` build sans erreur, et que l'`Info.plist` contient bien `NSExtensionPointIdentifier = com.apple.widgetkit-extension`.
- **« No content »** sur le widget : l'app n'a jamais tourné → snapshot absent → état D s'affiche, c'est attendu. Lancer l'app.
- **Widget ne se rafraîchit pas après review** : vérifier que les deux targets partagent bien le même `group.com.quentinaslan.Memoire` dans Signing & Capabilities.
- **Crash au tap deep-link** : vérifier que `RootView.handleDeepLink` est bien attaché — il y a un `.onOpenURL` dans `RootView.swift`.
