# ADR 0001 — iOS 18.0 minimum avec enhancement progressif iOS 26

**Date** : 2026-04-18
**Statut** : Accepté

## Contexte

Mémoire adopte Liquid Glass, langage visuel introduit par Apple à iOS 26 (WWDC 2025). Trois cibles étaient possibles :

- **iOS 26 uniquement** : code le plus simple (zéro `#available`), mais exclut ~34 % des iPhones actifs (66 % sur iOS 26 en avril 2026 selon les stats Apple)
- **iOS 18 + progressive enhancement iOS 26** : couvre ~90 % du marché, chaque usage de glass doit avoir un fallback solide
- **iOS 17 + progressive enhancement** : ~95 % de couverture, mais double la surface `#available` et prive des fixes SwiftData iOS 18.x

Le brief Liquid Glass commandé au début du projet (rapport externe de recherche) recommandait explicitement iOS 18 + progressive enhancement, citant la stratégie de l'app Grow (Editor's Choice, 173 pays).

## Décision

**Deployment target = `IPHONEOS_DEPLOYMENT_TARGET = 18.0`**, build sur SDK iOS 26 (Xcode 26.3+, obligatoire App Store depuis le 28 avril 2026).

Les API iOS 26 (`.glassEffect()`, `GlassEffectContainer`, `Glass`) sont gardées derrière `if #available(iOS 26.0, *)` — fallback solide `Color.surfaceRaised` en dessous.

L'opt-out `UIDesignRequiresCompatibility` n'est **pas** utilisé : Apple l'a annoncé supprimé en iOS 27, ce serait une dette à 6 mois.

## Conséquences

**Positives** :
- Couverture ~90 % vs 66 % — crucial pour une app payante
- Accès aux API iOS 18 sans compromis (`@Entry`, SwiftData `.fetchCount`, `@Observable`, `NavigationStack`)
- Alignement avec la trajectoire Apple et les apps premium de référence (Matter, GoodLinks, Fantastical)

**Négatives** :
- Un seul modificateur central (`memoireSurface`) doit gérer le branchement iOS 26 vs fallback. Acceptable : 20 lignes dans `GlassSurface.swift`, pas de duplication
- iOS 17 users exclus (~5 %) — acceptable vs le coût de double `#available`

## Alternatives considérées

- **iOS 26 only** — rejeté : portée commerciale insuffisante
- **iOS 17** — rejeté : double surface `#available`, perte de fixes SwiftData, gain marginal (~5 %)
