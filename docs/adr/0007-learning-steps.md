# ADR 0007 — Learning steps en app-layer

**Date** : 2026-04-22
**Statut** : Accepté

## Contexte

Le `ShortTermScheduler` de 4rays fournit un seul intervalle intra-session avant graduation (10 min → FSRS). Deux problèmes :

- Une carte nouvelle notée **Easy** graduait directement vers Review à ~15 jours, contournant toute phase d'apprentissage. Un hack `Easy → Good` dans `CardFSRSAdapter` masquait ce comportement mais corrompait le signal FSRS.
- Une seule étape avant graduation est insuffisante pour la consolidation mnésique, surtout pour des apprenants TDAH.

Les learning steps ne font pas partie de la spec FSRS — ils relèvent d'une décision produit sur la UX d'apprentissage (cf. Anki, ts-fsrs).

## Décision

Ajouter une surcouche **learning steps** gérée entièrement dans `ReviewSession`, sans modifier le package FSRS.

**Steps** : `[10 min, 1 h, 1 j]` — configurés dans `AppConstants.LearningSteps.steps`.

**Champ ajouté** sur `Card` : `learningStep: Int`
- `0..N` : index dans steps[], carte en apprentissage
- `-1` : graduée (Review ou Relearning), FSRS gère

**Règles dans `ReviewSession.applyLearningStep()`** :

| Rating | Action |
|---|---|
| Again | reset step 0, due = +10 min |
| Good | avance au step suivant, due = steps[step] ; si dernier step dépassé → graduation FSRS |
| Easy (step 0) | saute au dernier step, due = +1 j (force une nuit avant Review) |
| Easy (step > 0) | graduation FSRS immédiate |

**Easy au step 0** est traité différemment des autres : l'utilisateur vient de créer la carte, la réponse est encore en mémoire de travail. Graduer directement serait une fausse information sur la rétention réelle.

**FSRS n'est appelé qu'à la graduation.** Pendant les steps, `fsrsState` reste `.new`, `fsrsReps` est incrémenté manuellement. Le scheduler voit la carte comme neuve et initialise stability/difficulty correctement depuis le rating de graduation.

**Migration** (`SchedulerMigration` v2) : cards avec `fsrsReps > 0` → `learningStep = -1` (déjà graduées avant cette feature).

## Conséquences

**Positives** :
- Signal FSRS intact : Easy transmet le vrai signal de facilité à la graduation
- Consolidation à 3 intervalles (10 min, 1 h, 1 j) avant la première longue révision
- Pas de modification du package FSRS, pas de dépendance supplémentaire
- `DailyQueue` inchangé : les cartes en step ont `fsrsReps > 0` et `nextReviewDate <= now` quand dues

**Négatives** :
- `Card` gagne un champ SwiftData supplémentaire (migration légère, automatique)
- Easy au step 0 peut surprendre un utilisateur expert qui connait vraiment sa carte — acceptable pour le public cible TDAH

## Alternatives considérées

- **Remapping Easy → Good** (ancienne approche) : rejeté, corrompt le signal FSRS
- **Déléguer au ShortTermScheduler** : ses steps sont hardcodés (1/5/10 min), non configurables, et il graduate en 2 révisions au lieu de 3
- **Migration du package vers open-spaced-repetition/swift-fsrs** : différée, l'écart d'API est minime et n'apporte rien pour cette feature
