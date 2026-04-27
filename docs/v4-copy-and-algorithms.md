# Mémoire v4 — Copy & algorithmes

Document vivant. Source de vérité pour les **strings figées** et les **règles** (seuils, formules, tirages) introduits par la refonte v4 (CardDetail, DeckDetail, Onboarding écran 4, CompleteScreen, Toast, half-sheets).

**Quand mettre à jour** : à chaque refactor qui touche une copy ou un seuil. Si tu ajoutes/modifies une phrase ou un seuil dans le code, **réplique le changement ici**. Si tu changes une règle algo, **mets à jour la formule ici**.

**Doctrine A** (rappel) : FSRS reste invisible. Pas de page « Comment ça marche », pas de chiffres bruts FSRS. Seules surfaces pédagogiques : 2 ⓘ half-sheets + onboarding écran 4. Toute exception (ex : Prochain palier) est documentée explicitement.

## 0. Ratings — boutons de notation

Source : `Memoire/Rating.swift` (enum `Rating.label`). **Source unique** — tout texte qui mentionne un rating dans l'UI doit utiliser `Rating.X.label` plutôt qu'un literal, pour éviter la dérive si on rebrand encore.

| Rating | rawValue | label affiché | Signification |
|---|---|---|---|
| `.again` | 1 | **À revoir** | Je n'ai pas réussi, recommençons |
| `.good`  | 3 | **Connu**     | Je l'ai retrouvé, avec un peu d'effort (le rating standard) |
| `.easy`  | 4 | **Évident**   | Instantané, sans effort — pousse l'intervalle plus loin |

Les labels précédents ("Moyen" / "Facile") ont été abandonnés : "Moyen" sonnait comme un jugement de valeur en français courant alors qu'il représente le rating standard, et "Facile" ne se distinguait pas assez de "Moyen" en clarté.

---

## 1. Status words CardDetailScreen (5 cas)

Source : `Memoire/CardDetailScreen.swift` — enum privé `CardStatusWord`.

### Résolution (priorité descendante)

```
1. À revoir bientôt   → state != .new ET (retrievability < 0.7 OU overdue ≥ 24h)
2. À découvrir         → state == .new
3. En train de se former → state == .learning OU .relearning OU (.review ET stability < 7d)
4. Ancrée              → .review ET stability ≥ 21d ET retrievability ≥ 0.9
5. Familière           → fallback (.review ET 7d ≤ stability < 21d)
```

Constantes (`AppConstants.FSRS`) :
- `consolidatingStabilityDays = 7` — seuil bas
- `solidStabilityDays = 21` — seuil haut

### Couleurs

| Status | Token / hex | Notes |
|---|---|---|
| À découvrir | `Color.gold.opacity(0.6)` | Or atténué |
| En train de se former | `#C8B07A` | Tan tiède, encapsulé dans l'enum |
| Familière | `Color.gold` (#D4AF37) | Or plein |
| Ancrée | `Color.gold` (#D4AF37) | Or plein |
| À revoir bientôt | `#C8A88A` | Pêche tiède, pas de rouge (anti-shame) |

### Insight sentences (3 par status, 15 total)

Tirage aléatoire stable par visite (seed dans `@State`).

**À découvrir** :
- Tu vas la rencontrer bientôt.
- Cette carte attend son premier tour.
- Première rencontre à venir.

**En train de se former** :
- Cette carte cherche encore son rythme.
- Elle revient souvent — c'est normal au début.
- Mémoire l'espace progressivement.

**Familière** :
- Tu retrouves cette carte sans effort. Elle tient bien.
- Elle revient maintenant à intervalle confortable.
- Cette carte a trouvé son rythme.

**Ancrée** :
- Cette carte est solidement installée.
- Tu peux compter sur elle longtemps.
- Elle ne reviendra pas avant un bon moment.

**À revoir bientôt** :
- Mémoire la ramène pour toi cette semaine.
- Elle redemande un passage — rien de cassé.
- Cette carte demande une nouvelle visite.

---

## 2. ~~Difficulté reformulée~~ — supprimée

La phrase conditionnelle « Tu la retrouves facilement. » / « Cette carte te demande encore de l'effort. » a été retirée de CardDetailScreen lors d'un audit anti-redondance : trop de surfaces parlaient de la même solidité (status word + insight + label SOLIDITÉ + sheet ⓘ + cette phrase). Le status word + son insight assurent déjà ce signal sans dupliquer.

Le seuil `mediumDifficultyThreshold = 7.0` reste dans `AppConstants.FSRS` au cas où la phrase reviendrait — il est inactif pour l'instant.

---

## 3. Prochain palier (CardDetailScreen)

**Exception assumée à la doctrine A** — montre l'effet d'une notation sans nommer FSRS.

Source : `CardDetailScreen.prochainPalierLine`.

### Conditions d'affichage

Affiché UNIQUEMENT si :
- `card.learningStep == -1` (graduée, FSRS pilote)
- `state == .review`
- `nextReviewDate > .now` (pas overdue)
- `fsrsLastReview != nil`

Skip pour : `.new`, `.learning`, `.relearning`, et toute carte overdue.

### Format

```
Si tu réponds **{Rating.good.label}**, prochaine révision dans {projectedDuration} au lieu de {currentDuration}.
```

- `Rating.good.label` = source unique pour le mot du bouton (actuellement « Connu »)
- `currentDuration` = `formatDuration(days: card.fsrsStability)`
- `projectedDuration` = `formatDuration(days: card.projectedNextReviewDate(rating: .good))`
- Le mot du rating est en NY Serif 16pt semibold gold via `AttributedString`

### API technique

`FSRSScheduler.previewSchedule(card:rating:at:) -> SwiftFSRS.Card` — non-mutante. Retourne le résultat sans appliquer à la Card SwiftData.

`Card.projectedNextReviewDate(rating:using:) -> Date?` — wrapper qui retourne nil si `learningStep != -1`.

---

## 4. Date de naissance (CardDetailScreen)

Source : `CardDetailScreen.birthLabel`.

```
0   jour  → "Apprise aujourd'hui"
1   jour  → "Apprise hier"
2-6 jours → "Apprise il y a {n} jours"
7-13 jours → "Apprise il y a 1 semaine"
14-29 jours → "Apprise il y a {n} jours"  (utilité du chiffre exact à ce range)
30-59 jours → "Apprise il y a 1 mois"
60-364 jours → "Apprise il y a {n/30} mois"
≥365 → "Apprise il y a plus d'un an"
```

Style : SF Pro 12pt medium secondary.

---

## 5. Truncation des durées (formatDuration)

Source : `CardDetailScreen.formatDuration` ET `DeckDetailScreen.formatStability` (logique dupliquée — extraire dans un helper si on touche encore).

```
< 1     → "moins d'un jour"
1       → "1 jour"
2-6     → "~{n} jours"
7-13    → "~1 semaine"
14-20   → "~2 semaines"
21-29   → "~3 semaines"
30-59   → "~1 mois"
60-89   → "~2 mois"
90-179  → "~3 mois"
180-364 → "~6 mois"
365-729 → "~1 an"
≥730    → "plus d'un an"
```

Tabular nums obligatoire sur ces affichages.

---

## 6. Prochaine révision — variantes (CardDetailScreen.nextReviewLabel)

```
nextReviewDate == nil → "À ta prochaine session"
overdue (≤ .now)      → "Disponible maintenant"
isToday + .learning/.relearning → HHhmm exact
isToday + autre       → "Plus tard aujourd'hui"
isTomorrow, hour < 14 → "Demain matin"
isTomorrow, hour ≥ 14 → "Demain soir"
2-6 jours             → "Dans {n} jours · {jour de semaine}"
7-13 jours            → "La semaine prochaine"
14-29 jours           → "Dans environ {n/7} semaines"
30-89 jours           → "Dans environ {n/30} mois"
90-364 jours          → "Dans plusieurs mois"
≥365                  → "L'an prochain"
```

---

## 7. Timeline 10 notations (CardDetailScreen)

Source : `CardDetailScreen.timelineSection`.

- 10 cellules `RoundedRectangle(cornerRadius: 3)`, hauteur 32pt, gap 4pt
- Couleur = `Rating.tint` :
  - `.again` → `Color.stateAgain` (#F7A58C)
  - `.good` → `Color.gold` (#D4AF37)
  - `.easy` → `Color.stateEasy` (#4ADE80)
- Cellules vides (carte avec < 10 reviews) : `Color.gold.opacity(0.10)`
- Ordre : oldest left → most recent right (chronologique de lecture)
- Pad : si N reviews < 10, les `10-N` cellules de gauche sont vides

---

## 8. Stability bands (DeckStats)

Source : `Memoire/Models/DeckStats.swift`.

Per-card classification (`Card.stabilityBand`) :
```
overdue (nextReviewDate ≤ .now)         → .toBack
stability ≥ 21 (solidStabilityDays)     → .solid
stability ≥ 7  (consolidatingStability) → .consolidating
sinon                                    → .toBack
```

Composition bar segments (`Memoire/Shared/CompositionBar.swift`) :
- Stables : `Color.gold` (#D4AF37)
- En consolidation : `#9A8556` (gold faded ~65%)
- À ramener : `#5A5550` (warm gray, jamais rouge)

Ordres dans la bar : Stables → En consolidation → À ramener (gauche → droite, du plus stable au moins stable).

---

## 9. DeckDetailScreen headline

Source : `DeckDetailScreen.headlineText`.

```
total == 0       → "Ce paquet est vide. Ajoute ta première carte."
solid == 0       → "Aucune carte encore consolidée. {n} {carte|cartes} en attente."
solid == total   → "Tout ce paquet est consolidé."
sinon (total==1) → "{solid} / {total} carte consolidée"
sinon            → "{solid} / {total} cartes consolidées"
```

---

## 10. DeckStatsSheet — copy

Source : `Memoire/Sheets/DeckStatsSheet.swift`.

### Section "Cette semaine"

```
0  → "Rien à revoir cette semaine."
1  → "Environ 1 carte à revoir cette semaine."
≥2 → "Environ {n} cartes à revoir cette semaine."
```

### Section forecast 7 jours

- Day labels : `"Aujourd'hui"` pour offset 0, sinon `EEEE` (locale fr_FR, capitalized).
- Counts : `"—"` si 0, sinon `"~{n} carte|cartes"`.
- Disclaimer italique :

> Mémoire ne prédit pas plus loin que 7 jours — au-delà, c'est trop incertain.

---

## 11. CompleteScreen — sentences (3 registres, 18 max, tirage pondéré)

Source : `Memoire/CompleteScreen.swift` — `CompletionInsight`.

### Conditions d'activation

- `uniqueCount < 3` → R1 only (R2 et R3 n'ont pas de sens sur 1-2 cartes)
- `uniqueCount ≥ 3` → tirage pondéré 3/8 R1, 3/8 R2, 2/8 R3

### Anti-répétition

`AppPreferences.lastShownInsightID` persiste l'ID de la dernière sentence affichée. Filtre du pool actif au tirage. Fallback sur le pool entier si tout est filtré.

### R1 — descriptif (5 phrases avec substitution `{n}`)

```
r1.consolidated   → "{n} {carte|cartes} consolidées aujourd'hui."
r1.session_done   → "Session terminée. {n} {carte|cartes} revues."
r1.behind_you     → "{n} {carte|cartes} derrière toi."
r1.morning (heure < 14) → "Tu as bouclé {n} {carte|cartes} ce matin."
r1.evening (heure ≥ 14) → "Tu as bouclé {n} {carte|cartes} ce soir."
r1.close_book     → "{n} {carte|cartes} — tu peux refermer."
```

### R2 — interprétatif (5 phrases ; les 2 du brief nécessitant des deltas cross-session sont droppées)

```
r2.gained_solid    → "{n} {carte|cartes} ont gagné en solidité aujourd'hui."
r2.holds_better    → "Ton paquet tient un peu mieux qu'hier."
r2.come_back_later → "Ces {n} {carte|cartes} reviendront plus tard cette fois."
r2.extends_gap     → "Mémoire prolonge l'écart sur {n} {carte|cartes}."
r2.responds_well   → "Sur ces {n} {carte|cartes}, ta mémoire répond bien."
```

### R3 — pédagogie douce (6 phrases, kill criteria : ≥3/30 testeurs reportent "scolaire")

```
r3.brings_back        → "Mémoire ramènera ces cartes pile avant que tu ne les oublies."
r3.no_force           → "Tu n'as rien à mémoriser de force — Mémoire programme le retour."
r3.invisible_work     → "Le travail invisible se passe entre les sessions."
r3.spacing_grows      → "Plus tu reviens, plus l'espacement grandit."
r3.gap_makes_memory   → "C'est l'écart entre les révisions qui fait la mémoire."
r3.holds_longer       → "Ce que tu retrouves aujourd'hui tiendra plus longtemps."
```

---

## 12. ReviewToast — Permission to fail

Source : `Memoire/ReviewToast.swift` + trigger dans `ReviewScreen.evaluateToastTrigger`.

### Conditions de déclenchement

```
session.completedRatings.last == .again
ET prefs.cumulativeAgainCount ≥ 3
ET !prefs.permissionToFailToastShown
→ affiche, flag = true (one-shot lifetime)
```

`cumulativeAgainCount` est incrémenté dans `ReviewSession.rate()` à chaque `.again`. Cumulatif toutes sessions.

### Copy (2 variantes)

- Default : `"À revoir, ce n'est pas un échec — c'est de l'information."`
- Si `prefersReducedMotion == true` : `"À revoir signale à Mémoire de revenir bientôt."`

### Présentation

- Liquid Glass `.regularMaterial` via `.memoireSurface`
- Top safe area + 12pt
- Auto-dismiss après 4s
- Tap pour dismiss immédiat
- Animation entry/exit avec `prefersReducedMotion` fallback

---

## 13. Onboarding écran 1 — NamePage

Source : `OnboardingFlow.NamePage`.

### Copy

```
Sous-titre (italique) :  On va faire connaissance.
Titre :                  Comment tu t'appelles ?
Placeholder TextField :  Ton prénom
```

Pas de helper text — la question parle d'elle-même, le bouton « Passer » signale que c'est optionnel.

### Animation

Cascade fade-in 280 ms easeOut, 60 ms entre chaque bloc (sous-titre → titre → champ). Identique à `TwoWordsPage`. `prefersReducedMotion` désactive la cascade.

### Comportement

- Champ optionnel — laisser vide ne bloque pas la progression.
- Binding identique à `SettingsScreen` : `get: { prefs.firstName ?? "" }`, `set: { prefs.firstName = $0 }`.
- Sanitisation gérée par `AppPreferences.firstName.didSet` (trim + 20 chars max).
- Clavier dismissé via `KeyboardDismisser.dismiss()` (UIKit `resignFirstResponder`) sur : submit (OK/Entrer), tap hors champ, tap CTA, swipe de page. `@FocusState` seul est unreliable dans un `TabView` paginé.

### Position

2e page (tag 1) du `TabView` dans `OnboardingFlow`, juste après la WelcomePage (splash). La page 0 reste un pur moment de marque, sans interaction. `AppConstants.Onboarding.pageCount = 6`.

---

## 13b. Onboarding écran 5 — TwoWordsPage

Source : `OnboardingFlow.TwoWordsPage`.

### Copy verrouillée

```
Titre :   Deux mots à connaître

Intro :   Mémoire mesure deux choses pour chaque carte.

Para 1 :  La solidité : à quel point un souvenir tient. Plus tu retrouves
          une carte, plus elle se solidifie.

Para 2 :  La fraîcheur : la probabilité que tu t'en souviennes encore
          aujourd'hui. Quand elle baisse, Mémoire la ramène.

Coda :    Tu n'as rien à régler.
          Mémoire s'en occupe.

CTA :     J'ai compris (sur la dernière page d'OnboardingFlow)
```

### Animation

Cascade fade-in 280ms easeOut, 60ms entre chaque bloc. `prefersReducedMotion` désactive la cascade et la translation.

### Position

6e page (tag 5) du `TabView` dans `OnboardingFlow`. `AppConstants.Onboarding.pageCount = 6`.

---

## 14. Half-sheets ⓘ — Solidité & Fraîcheur

Source : `Memoire/Sheets/EditorialSheet.swift`. Pattern partagé + 2 factory functions `EditorialSheet.solidite()` et `EditorialSheet.fraicheur()`.

### Solidité

```
Titre : Solidité

P1 :    La solidité, c'est combien de temps un souvenir tient avant qu'on
        doive le revoir.

P2 :    Quand tu retrouves une carte sans trop d'effort, sa solidité
        augmente — Mémoire l'espace alors davantage. Quand tu hésites,
        elle redescend, et la carte revient plus tôt.

Coda :  Tu n'as rien à régler. Mémoire s'en occupe.

Footnote (rétractée) :
        ▸ En anglais : Stability
          En anglais, on parle de « Stability » — c'est la même chose.
```

### Fraîcheur

```
Titre : Fraîcheur

P1 :    La fraîcheur, c'est la probabilité que tu te souviennes encore
        d'une carte aujourd'hui.

P2 :    Plus le temps passe sans révision, plus elle baisse. Quand elle
        descend trop, Mémoire ramène la carte avant que tu ne l'oublies
        vraiment.

P3 :    On ne te montre pas un pourcentage qui descend en direct — ce
        serait du bruit. Mémoire s'en occupe en silence.

Coda :  Tu fais le rappel. Mémoire fait le calcul.

Footnote (rétractée) :
        ▸ En anglais : Retrievability
          En anglais, on parle de « Retrievability » — c'est la même chose.
```

### Présentation

- `.presentationDetents([.medium])`
- Header zone : Liquid Glass autorisé (chrome)
- Body zone : `Color.bgPrimary` opaque (pas de glass sur lecture éditoriale)
- Coda en NY Serif 17pt italique, `Color.gold.opacity(0.8)`

---

## 15. Empty / error / loading states

| Surface | Cas | Copy |
|---|---|---|
| DeckDetail | deck vide | « Aucune carte pour l'instant. » + CTA « + Ajouter une carte » (existant, préservé) |
| CardDetail | carte nouvelle | Status "À découvrir" + insight + Solidité `—` ; Vues = 0 ; timeline 10 cellules vides |
| Home | aucune carte due | EmptyDueState (existant, géré ailleurs) |

---

## 16. Pointeurs vers le code

| Concept | Fichier |
|---|---|
| Status word | `Memoire/CardDetailScreen.swift` (enum privé) |
| Prochain palier | `Memoire/CardDetailScreen.swift` (`prochainPalierLine`) + `Scheduling/CardFSRSAdapter.swift` (`projectedNextReviewDate`) + `Scheduling/FSRSScheduler.swift` (`previewSchedule`) |
| Timeline notations | `Memoire/CardDetailScreen.swift` (`timelineSection`) |
| Composition bar | `Memoire/Shared/CompositionBar.swift` |
| Deck stats helpers | `Memoire/Models/DeckStats.swift` |
| Half-sheets pattern | `Memoire/Sheets/EditorialSheet.swift` |
| Deck stats sheet | `Memoire/Sheets/DeckStatsSheet.swift` |
| Completion sentences | `Memoire/CompleteScreen.swift` (`CompletionInsight`) |
| Toast trigger | `Memoire/ReviewScreen.swift` (`evaluateToastTrigger`) + `Memoire/ReviewToast.swift` |
| Onboarding écran 4 | `Memoire/OnboardingFlow.swift` (`TwoWordsPage`) |
| Retrievability | `Memoire/Scheduling/CardFSRSAdapter.swift` (`Card.currentRetrievability`) |
| Stability bands | `Memoire/Models/DeckStats.swift` (`Card.stabilityBand`) |
| Cumulative again counter | `Memoire/AppPreferences.swift` + `Memoire/ReviewSession.swift` |

---

## 17. Différés (post-feedback)

À considérer après usage réel — n'ajoute pas si pas demandé :

- ⓘ toolbar caché de CardDetailScreen avec « créée le / vue X fois » (le `birthLabel` couvre déjà la première info)
- Constellation Mémoire 6 mois (requiert ≥180j de données)
- Pyramide 4 tiers, Heatmap per-deck (rejetés par brief)
- Variante factuelle alternative du toast (heuristique 2-skips)
- Animations de polish : draw progressif sparkline, easing fines des transitions

---

## 18. Kill criteria (mesurables sur usage réel)

| Métrique | Cible | Trigger kill/simplify |
|---|---|---|
| ⓘ Solidité tap rate sur 30j | 8-25% | < 3% → retirer ⓘ ; > 40% → définition pas internalisée, revoir onboarding 4 |
| Registre 3 CompleteScreen perçu "scolaire" | 0 testeur sur 30 | ≥ 3/30 → drop registre 3, repondérer 50/50 R1 R2 |
| Toast tap-dismiss avant 4s | < 30% | > 50% → décaler trigger au 5e .again ou retrait |
| Sheet DeckDetail drag medium → large | 30-60% | < 20% → retirer le forecast 7j du large, garder seulement medium |
| CardDetail flip card recto/verso | ≥ 80% des visites flippent | < 50% → ajouter affordance plus claire ou afficher recto+verso stacked |
| Status words confusion (Familière vs Ancrée) | < 2/30 testeurs | ≥ 3/30 → merger en "Stable" + drop "Ancrée" |
