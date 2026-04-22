# ADR 0002 — Liquid Glass chrome-only via `memoireSurface`

**Date** : 2026-04-18
**Statut** : Accepté

## Contexte

Mémoire cible des adultes TDAH. La littérature (Kooij & Bijlenga 2014) rapporte ~69 % de photophobie dans cette population. Liquid Glass cumule trois triggers documentés : *lensing* temps réel, *specular highlights* qui suivent le gyroscope, *bright flashing feedback* sur pression.

Trois postures envisagées :

- **Full embrace** — glass partout (y compris carte de révision, listes)
- **Skip total** — opt-out `UIDesignRequiresCompatibility` (dette à 6 mois)
- **Adoption sélective chrome-only** — glass uniquement sur la couche de navigation flottante (tab bar, toolbar, sheets, CTA, boutons FSRS)

Le brief Liquid Glass externe ayant analysé Apple HIG, WWDC session 219, la doctrine Apple elle-même (« Liquid Glass is best reserved for the navigation layer that floats above the content »), et le Infinum Accessibility Audit (ratios de contraste descendant à 1.5:1 sur glass) a tranché pour la troisième option.

## Décision

**Chrome uniquement**. Implémenté via un **unique modificateur** `.memoireSurface(in:tint:interactive:)` dans `Mémoire/GlassSurface.swift`.

Règles :
- Interdiction d'appeler `.glassEffect()` directement dans le code de l'app
- Variante `.clear` bannie du code base
- Un seul élément glass par écran idéalement
- Texte éditorial (serif New York, flashcards, métadonnées) toujours sur surface **solide** (`surfaceElevated #232325` ou `surfaceRaised #2A2A2C`)

Le modificateur respecte automatiquement :
- **iOS 18 fallback** : si `#available(iOS 26.0, *)` échoue, retombe sur solide
- **Reduce Transparency** (réglage système) : force solide
- **Mode Calme** (toggle in-app, `prefs.calmMode`) : force solide — indispensable pour user TDAH qui ne va pas naviguer dans Réglages iOS avant la 1ère session

Or dédoublé dans les tokens :
- `gold #D4AF37` sur surfaces solides
- `goldOnGlass #E6C558` (pré-éclairci) uniquement pour `.glassProminent` sur CTA paywall

## Conséquences

**Positives** :
- Contrat WCAG AAA 15:1 préservé sur tout le texte critique (vit sur solide)
- Adaptation automatique aux préférences système + in-app — zéro code à chaque callsite
- Identité « calm luxury » préservée ; typographie New York non déformée par la vibrancy

**Négatives** :
- Le modificateur est un point de couplage obligatoire. Compensé par sa centralisation (1 fichier, 20 lignes)
- Certains contributeurs seront tentés de bypass via `.glassEffect()`. Mitigation : règle documentée ici + en-tête dans `GlassSurface.swift`, grep de `glassEffect` dans le code base comme check CI potentiel

## Alternatives considérées

- **Full embrace** — rejeté : viole AAA 15:1, déstabilise TDAH/photophobes, contradiction avec la doctrine Apple elle-même
- **Skip total via `UIDesignRequiresCompatibility`** — rejeté : Apple supprime le flag en iOS 27, dette à 6 mois, rend l'app datée aux early adopters iOS 26+
