# scripts/

Outils de maintenance du projet, hors build standard.

## `sync-xcstrings.py`

Synchronise les traductions EN et les règles CLDR plurielles dans `Memoire/Resources/Localizable.xcstrings`.

### Pourquoi ce script existe

Le catalog Xcode ne supporte ni l'édition en bulk EN, ni la définition programmatique de pluriels. Maintenir ~250 strings + ~30 pluriels à la main dans le JSON est fragile (typos, oublis, mauvais format `%1$@`). Ce script est la **source unique de vérité pour les paires FR → EN**.

### Quand l'utiliser

À chaque fois qu'une nouvelle string utilisateur en français est ajoutée dans le code (`Text("…")`, `String(localized: "…")`, etc.) :

1. Build le projet pour que Xcode ré-extraie les strings :
   ```bash
   xcodebuild -project Memoire.xcodeproj -scheme Memoire \
       -destination 'generic/platform=iOS Simulator' build
   ```
2. Ouvre `Localizable.xcstrings` une fois dans Xcode (l'éditeur synchronise automatiquement les nouvelles clés depuis les `.stringsdata`).
3. Ajoute la nouvelle paire FR → EN dans le `TRANSLATIONS` du script (ou la règle dans `PLURALS` si la string contient `%lld carte/cartes`).
4. Lance le script :
   ```bash
   python3 scripts/sync-xcstrings.py
   ```
5. Re-build pour vérifier que le catalog compile.

### Sortie attendue

```
Catalog:    /…/Memoire/Resources/Localizable.xcstrings
Total keys: 234
Covered:    234
Missing:    0
```

Si `Missing: > 0`, le script liste les clés non couvertes et exit avec code `1`. Ajoute-les à `TRANSLATIONS` ou `PLURALS` puis relance.

### Limites connues

- Les strings multi-arg sans CLDR plural (ex. `%lld jours d'affilée · %lld derniers jours`) sont traduites directement — Xcode ne sait pas inférer quel `%lld` pluraliser quand il y en a plusieurs. Si l'un des arguments doit varier en singulier, il faut split la phrase au call site.
- Les footnotes pédagogiques EditorialSheet "En anglais : Stability/Retrievability" sont **inversées** en EN ("In French: Solidité/Fraîcheur") — préservation de la valeur pédagogique pour chaque langue.
- `STRING_CATALOG_GENERATE_SYMBOLS` est `NO` au niveau projet : certaines clés FR proches (« Effacer le dessin » vs « Effacer le dessin ? ») provoquent des collisions de symboles auto-générés. La sécurité vient du source-as-key, pas des symboles.
