# ADR 0008 — Passe UX/TDAH sur l'Accueil

**Date** : 2026-04-24
**Statut** : Accepté

## Contexte

L'écran Accueil (`HomeScreen.swift`) était fonctionnel mais contenait plusieurs
frictions et petits mensonges qui sapent le « plaisir » recherché pour
l'utilisateur cible (adultes TDAH) :

- Salutation codée en dur : `"Bonsoir, Quentin."` — faux à 10 h du matin, faux
  pour tout non-Quentin.
- Estimation de temps statique : `"≈ 5 minutes"` quel que soit `cardsDue` →
  sous-estime pour 50 cartes, sur-estime pour 3 cartes. Les cerveaux TDAH sont
  hypersensibles aux estimations malhonnêtes ("ça devait prendre 5 min…").
- Label du ring `"CARTES À RÉVISER"` toujours pluriel, même pour 1 carte.
- CTA `"Commencer la révision"` froid, institutionnel.
- Branche morte `"Avancer quelques cartes"` (CTA `else`) inatteignable : l'état
  "Journée terminée" prend déjà la place du CTA quand `cardsDue == 0`.
- Score de régularité `{n}/30` abstrait, sans notion de streak consécutif —
  le ressort dopaminergique "jour d'affilée" n'était pas exploité.
- Pas de hook vers "demain" dans l'état "Journée terminée" : l'utilisateur sort
  sans savoir quand revenir.
- `calmMode` ignoré par les animations de l'Accueil (`.numericText` sur le
  chiffre, anim de fill du ring).

Passe effectuée : revue UX + revue critique Opus 4.7 (double filtre
**UX best practices** + **TDAH-friendly**).

## Décisions

Pour chaque item, on explicite le *pourquoi TDAH*. Les alternatives rejetées
sont en fin de document.

### H1 — Salutation dynamique (`HomeScreen.greetingLine`)

- Sélection par heure : 5-11 h → `"Bonjour"`, 12-17 h → `"Bon après-midi"`,
  18-23 h → `"Bonsoir"`, 0-4 h → `"Bonne nuit"`.
- Nouveau champ `AppPreferences.firstName: String?` (UserDefaults, `@Observable`,
  sanitize + cap 20 chars via `AppConstants.User.firstNameMaxLength`).
  Saisi dans `SettingsScreen` (optionnel, skippable).
- Rendu : prénom défini → `"\(greeting), \(prénom)."` ; nil → `"\(greeting)"`
  sans point (typo française, hero slot, plus vivant que `"Bonsoir."`).

**Pourquoi TDAH** : la première ligne est la poignée de main émotionnelle.
Un `"Bonsoir"` à 9 h casse la confiance ; un prénom baisse l'activation energy.

### H2 — Estimation de temps honnête (`HomeScreen.ctaSubtitle`)

- Constante `AppConstants.FSRS.avgSecondsPerCard = 12`. La littérature FSRS
  donne 8-12 s/carte en régime ; on prend le haut pour sous-promettre.
- Arrondi : `< 60 s → ≈ 1 minute` ; `60-600 s → minute entière pluralisée` ;
  `> 600 s → multiple de 5` ; `> 100 cartes → "≈ 20 minutes ou plus"`
  (anti-ancrage).
- Pluriel de `carte` géré côté sous-titre.
- **Garde-fou nuit (0-4 h)** : remplace l'estimation par
  `"À faire quand vous voulez."`.

**Pourquoi TDAH** : les cerveaux TDAH sur-ancrent sur les chiffres. Dépasser
une promesse déclenche un spiral de honte ; afficher "30 min" à minuit fuel
l'hyperfocus nocturne qui se paie cher au réveil.

### H3 — Label ring singulier/pluriel

- `cardsDue == 1` → `"CARTE À RÉVISER"`, sinon `"CARTES À RÉVISER"`.
- On garde le nom-mené : `"12"` suivi de `"CARTES À RÉVISER"` ancre le sens.
  `"À REVOIR AUJOURD'HUI"` considéré puis rejeté (ambigu : "12 quoi ?").

### H4 — CTA « Réviser » (`HomeCopy.ctaLabel`)

- `cardsDue == 1` → `"Réviser une carte"`
- `2…5` → `"Réviser \(n) cartes"`
- `> 5` → `"Réviser"` (le compte reste visible dans le sous-titre H2)

**Pourquoi TDAH** : deux itérations ici. Première tentative = `"Avancer"`,
reframing dopaminergique / forward-motion. Deuxième passe après revue UX
indépendante : switch vers `"Réviser"`.

Arguments qui ont fait basculer :
1. **Cohérence label→CTA** : le label du ring dit déjà `"CARTES À RÉVISER"`.
   Reprendre le même verbe élimine la micro-traduction mentale `"avancer → ah
   oui les cartes"` (× 365 ouvertures/an).
2. **Charge morale cachée** : en français, "avancer" porte `"avance dans la
   vie"`, `"faut avancer"` — registre subtilement culpabilisant, casse
   l'intention anti-shaming.
3. **Prévisibilité TDAH** : la littérature task-initiation (Ladder Method,
   Tiimo) pointe que le frein n'est pas le *nom* de la tâche mais le flou
   sur ce qui va se passer. `"Réviser"` est précis, `"Avancer"` est générique.
   Le sous-titre `"≈ 5 minutes"` gère déjà l'activation energy.
4. **Registre dark luxury** : `"Réviser"` est sobre, sérieux, aligné typo
   serif. `"Avancer"` sonne coach de vie générique.

Alternatives rejetées : `"Commencer"` (faux en jour 2+), `"Continuer"`
(présume un état en cours), `"On y va"` / `"C'est parti"` (infantilisant,
casse le dark luxury), `"Poursuivre"` (défendable mais moins précis).

### M1 — Indice prochaine révision (`EmptyDueState.nextReviewHint`)

Sous la capsule or de "Journée terminée", une ligne tertiaire :
- `+1 j` → `"Prochaine révision demain."`
- `2-6 j` → `"Prochaine révision dans \(n) jours."`
- `7 j` → `"Prochaine révision dans une semaine."`
- `8-14 j` → `"Prochaine révision dans \(n) jours."`
- `> 14 j` → `"Prochaine révision le 12 mai."` (`d MMMM` fr_FR)
- aucune carte future → ligne omise.

Exposé via `DailyQueue.nextDueDate(allCards:)`.

**Pourquoi TDAH** : sans hook vers demain, l'utilisateur sort sans signal de
retour — le loop dopaminergique est coupé. Pour >14 j on montre une date
absolue : "dans 47 jours" lit comme "l'app m'a oublié".

### M2 — Suppression du code mort

Branche `else` du ternaire CTA (`"Avancer quelques cartes"`) retirée : elle
était inatteignable (l'état B remplace déjà l'état C quand `cardsDue == 0`).
On garde `guard !dueCards.isEmpty { return }` dans l'action du bouton comme
ceinture-et-bretelles.

### M3 — Streak dans la carte régularité

Sous-titre désormais calculé (`HomeScreen.regularitySubtitle`) :
- `streak == 0` → `"30 derniers jours"`
- `streak == 1` → `"1 jour d'affilée · 30 derniers jours"`
- `streak ≥ 2` → `"\(n) jours d'affilée · 30 derniers jours"`

Nouvelle fonction `RegularityCalculator.currentStreak(reviews:)` : consécutifs
terminant **aujourd'hui OU hier**.

**Pourquoi TDAH (anti-flicker matinal)** : un user qui ouvre l'app à 8 h sans
avoir encore révisé voit son streak ancré sur hier plutôt que de tomber à 0
avant le café. Sinon : trois signaux négatifs empilés le matin (cartes dues
élevées + streak à 0 + régularité qui vient de baisser à minuit) → spiral
d'évitement.

### L2 — calmMode sur les animations d'accueil

- `.contentTransition(.numericText)` sur `cardsDue` → `.identity` si `calmMode`.

Respecte la doctrine photophobie/TDAH : le calme **est** la récompense, surtout
en État B.

### Cross-cutting

- **Pas de wall of status** : le streak n'est affiché qu'à un seul endroit
  (carte régularité). La ligne M1 reste dédiée à la prochaine révision.
- Aucune animation pulsée sur le rond or de l'état "Journée terminée".
- Les décisions sont documentées en commentaires `// TDAH:` aux call-sites où
  la raison n'est pas évidente à la lecture (garde-fou nuit, cap 100 cartes,
  fenêtre streak aujourd'hui-OR-hier, `avgSecondsPerCard = 12`).

## Alternatives rejetées

- **`avgSecondsPerCard = 10`** — trop optimiste. Warm-up + variance plus haute
  en population TDAH. Biais sous-promettre > sur-promettre en absence de
  télémétrie. À rendre adaptatif par user (médiane des 50 dernières reviews,
  clampée à [7, 20]) une fois la télémétrie dispo (V1.2+).
- **`"À REVOIR AUJOURD'HUI"`** comme label ring — rejeté : retire le nom et
  rend le grand chiffre ambigu.
- **`"Reprenez aujourd'hui"`** quand streak == 0 — rejeté : paternaliste, le
  ring héro rappelle déjà l'action.
- **Saut du prénom pendant l'onboarding** — reporté : trop de friction sur
  l'onboarding existant (4 écrans), le champ reste optionnel dans Réglages.
- **Animation pulsée sur le rond or "Journée terminée"** — rejeté : le calme
  est la récompense en État B, surtout pour calmMode/photophobie.

## Conséquences

**Positives** :
- L'Accueil devient une source de plaisir et non de honte (estimations
  honnêtes, streak qui ne flicke pas le matin, copy chaleureuse).
- Traçabilité : cet ADR + commentaires `// TDAH:` servent de source pour un
  futur bloc "Conçu pour les cerveaux TDAH" sur la landing page (claim adossé
  à des preuves).
- Pas de régression pour l'état "aucun deck" (inchangé).

**Négatives / dette** :
- `avgSecondsPerCard` reste une constante globale. Adaptatif par user attendra
  la télémétrie V1.2+.
- `firstName` vit dans `AppPreferences` (UserDefaults) — cohérent avec
  [ADR-0006](0006-apppreferences-vs-usersettings.md), migre vers `UserSettings
  @Model` en V1.1 avec le reste.
- `currentStreak` recalcule à chaque render. Perf négligeable (O(n) sur la
  liste de reviews, Set hashé). À mémoïser si profiling le justifie.

## À revisiter avec télémétrie

- `avgSecondsPerCard` → médiane par user des 50 dernières reviews.
- Buckets de temps → valider que les utilisateurs ne dépassent pas
  systématiquement l'estimation.
- Le streak aujourd'hui-OR-hier → vérifier qu'il ne cache pas une abandon
  réel (définir un seuil "hier inclus mais au-delà, reset").
