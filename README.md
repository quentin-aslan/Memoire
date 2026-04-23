# Mémoire

**Application iOS de répétition espacée, conçue pour les adultes TDAH.**

Mémoire t'aide à retenir ce qui compte vraiment — avec un algorithme scientifique, une interface sans friction, et un design pensé pour les cerveaux qui s'ennuient vite.

---

## Ce que fait l'app

Tu crées des **paquets de cartes** (vocabulaire, formules, concepts, etc.). Chaque jour, Mémoire te présente uniquement les cartes que tu as *besoin* de revoir ce jour-là — ni plus, ni moins.

Après avoir retourné une carte, tu notes ta mémoire :

- **À revoir** — tu n'y étais pas du tout
- **Moyen** — c'est venu, mais avec effort
- **Facile** — sans hésitation

L'algorithme ajuste automatiquement la prochaine date de révision pour chaque carte. Plus tu notes bien, plus la carte part loin dans le futur. Plus tu rates, plus elle revient vite.

---

## Stack

| Couche | Technologie |
|---|---|
| UI | SwiftUI (iOS 18+, iOS 26 progressif) |
| Persistance | SwiftData (local) |
| Algorithme | FSRS v5 via `swift-fsrs` (SPM) |
| Langage | Swift 5 |
| Cible minimum | iOS 18.0 |
| Build | Xcode 26+ / SDK iOS 26 |

---

## L'algorithme FSRS

FSRS (**Free Spaced Repetition Scheduler**) est l'algorithme de répétition espacée le plus avancé disponible open-source. Il est né comme alternative à l'algorithme SM-2 qu'Anki utilise depuis 30 ans.

**Comment ça marche ?**

Chaque carte a deux paramètres clés :
- **Stabilité** (S) : combien de jours la mémoire tient sans révision
- **Difficulté** (D) : à quel point la carte est dure à mémoriser

Après chaque révision, FSRS recalcule ces deux valeurs et programme la prochaine révision au moment précis où ta probabilité de te souvenir tombe sous le seuil de rétention configuré (90% par défaut).

**Ce que ça donne en pratique :**
- Une carte facile peut partir à 30, 90, 365 jours
- Une carte difficile revient en 1–3 jours jusqu'à consolidation
- Les cartes ratées (`.again`) sont repassées dans la même session jusqu'à mémorisation

**Intégration dans Mémoire :**
- Package `4rays/swift-fsrs` (FSRS v5)
- **Learning steps** `[10 min → 1 h → 1 j]` gérés dans `ReviewSession` avant graduation vers Review — FSRS n'est appelé qu'à la graduation (cf. `Scheduling/`)
- File quotidienne : cartes dues en retard d'abord, nouvelles cartes ensuite (plafond configurable, 10/jour par défaut)

---

## Design

Esthétique **dark luxury** :
- Fond quasi-noir `#1C1C1E`
- Or mat `#D4AF37` comme couleur accent principale
- Typographie **New York** (serif Apple) pour le contenu de mémorisation
- **Liquid Glass** sur le chrome uniquement (tab bar, boutons de notation) — jamais sur le texte

**Mode Calme** : désactive tous les effets visuels (glass, animations) pour les utilisateurs sensibles à la lumière ou en surcharge sensorielle — un cas fréquent chez les adultes TDAH.

---

## Structure du projet

```
Mémoire/
├── Models/              SwiftData (@Model Deck, Card, Review)
├── Scheduling/          Algorithme FSRS (wrapper, adaptateur, file quotidienne)
├── Features/Editor/     Création et édition de paquets et cartes
├── Services/            Notifications, calcul de régularité
├── *Screen.swift        Vues principales (Home, Review, Decks, Settings…)
└── Color+Tokens.swift   Palette de design tokens
    Typography.swift     Système typographique
    GlassSurface.swift   Point d'entrée unique pour Liquid Glass
```

---

## Fonctionnalités MVP

- [x] Onboarding 4 écrans (démo flip interactif, Mode Calme, notifications)
- [x] CRUD paquets et cartes
- [x] Session de révision avec flip 3D animé
- [x] Algorithme FSRS v5 intégré
- [x] File quotidienne intelligente (dues + nouvelles)
- [x] Score de régularité (30 jours glissants)
- [x] Mode Calme (accessibilité, photophobie)
- [x] Notifications quotidiennes configurables
- [x] Détail carte : état FSRS, difficulté, stabilité, historique
- [x] Soft delete (préparation sync future)
- [x] Accessibilité : VoiceOver, Reduce Motion, Reduce Transparency

---

## Roadmap (V1.1+)

- Sync Supabase + Sign in with Apple
- Thème clair
- Import Anki / CSV
- Widgets et Apple Watch
- Stats avancées
- Modifications FSRS adaptées au TDAH (variabilité, backlog-aware)

---

## Auteur

Quentin Aslan — [contact@quentinaslan.com](mailto:contact@quentinaslan.com)
