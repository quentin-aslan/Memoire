# ADR 0005 — swift-fsrs avec `ShortTermScheduler` exclusif

**Date** : 2026-04-19
**Statut** : Accepté

## Contexte

Le CDC §5 spécifie l'algorithme FSRS v5 pour le scheduling des révisions, avec le package `4rays/swift-fsrs` (MIT, maintenu, cité référence dans le CDC).

Le CDC précise aussi des **learning steps** initiaux : `1 min → 10 min → fin de session → jour suivant → FSRS`. Ces steps ne sont habituellement pas inclus dans les implémentations FSRS pures (ils relèvent de décisions produit).

Avant l'analyse du source, on envisageait d'écrire un composant maison `LearningStepsGraduator` gérant ces steps, au-dessus du scheduler FSRS.

Lecture du source du package (`Sources/SwiftFSRS/Schedulers/ShortTermScheduler.swift`) a révélé que **`ShortTermScheduler` implémente déjà** :

- La notion de `Status` (new, learning, review, relearning)
- Les transitions entre états sur les 4 ratings (again, hard, good, easy)
- Les intervalles courts en dur pour la phase learning :
  - `new + again` → learning, +1 min
  - `new + hard` → learning, +5 min
  - `new + good` → learning, +10 min
  - `new + easy` → review directement (interval FSRS)
  - `learning/relearning + again` → reste learning, +5 min
  - `learning/relearning + hard` → reste learning, +10 min
  - `learning/relearning + good/easy` → graduation vers review avec interval FSRS probabilistique

Trois options :

- **Implémentation maison complète** — contrôle total mais ~200 lignes à coder + tester
- **`LearningStepsGraduator` + `LongTermScheduler`** — couche perso au-dessus du package
- **`ShortTermScheduler` exclusif** — utilise le package tel quel, zéro couche additionnelle

## Décision

Utiliser **`ShortTermScheduler` exclusivement** du package `4rays/swift-fsrs`. Aucun `LearningStepsGraduator` maison.

Architecture :

```
Mémoire/Scheduling/
  FSRSScheduler.swift          wrapper qui appelle ShortTermScheduler.schedule(...)
  CardFSRSAdapter.swift        conversion @Model Card ↔ Card struct du package
```

Le wrapper :
1. Construit un `Card` (package) depuis les champs FSRS de notre `@Model Card`
2. Appelle `ShortTermScheduler().schedule(card:algorithm:reviewRating:reviewTime:)`
3. Copie les champs du `Card` mis à jour (status, due, stability, difficulty, reps, lapses, lastReview, scheduledDays, elapsedDays) vers notre `@Model`
4. Insère un `Review` log

L'enum `Rating` local passe de 3 à 4 cas pour matcher le package (ajout de `.hard`). `ReviewScreen` affiche 4 boutons dans un `GlassEffectContainer(spacing: 10)` sur iOS 26.

Le token `Color.stateHard` est ajouté (orange doux ≈ `#E8A867`), distinct des autres tints sémantiques.

Migration des cartes existantes : `SchedulerMigration.runIfNeeded(in: context)` au lancement — pour chaque carte, mapper `fsrsReps == 0 && fsrsLastReview == nil` → `status = .new`, sinon `status = .review`. Ne **jamais** régresser `nextReviewDate` existante (respect de l'utilisateur).

## Conséquences

**Positives** :
- ~40 % moins de code qu'avec graduator maison
- Pas de ré-implémentation d'un algorithme documenté — le package est calibré sur des millions de reviews réelles
- Probabilistiquement juste (stability/difficulty mis à jour via FSRS v5)
- Gain de maintenance : upgrades du package = upgrades de notre scheduler sans code à toucher
- Support natif des 4 états (new, learning, review, relearning) via `Status` enum du package

**Négatives** :
- Écart mineur vs CDC : les steps sont `[1min, 5min, 10min]` dans le package au lieu de `[1min, 10min, fin-de-session, jour-suivant]`. Acceptable : la carte revient 5 min après un again en learning, ce qui est encore plus rapide que la fin de session — plus favorable à l'utilisateur
- La notion de « fin de session » du CDC n'est pas dans le package. Elle pourrait être implémentée en V1.1 si pertinente (réinjection de la carte dans la queue de session en cours), sans toucher au scheduler

## Alternatives considérées

- **Implémentation maison complète** — rejeté : 200 lignes de math bayésienne à tester, haute probabilité de bugs subtils, pas de gain vs package officiel
- **Graduator custom + `LongTermScheduler`** — rejeté : ajoute une couche d'indirection pour re-implémenter ce qui est déjà dans `ShortTermScheduler`. Complexité gratuite
- **`LongTermScheduler` seul** — rejeté : ne gère que les intervalles ≥ 1 jour, les cartes neuves auraient directement des intervalles trop longs (pas de phase d'apprentissage)
