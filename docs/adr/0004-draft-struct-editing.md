# ADR 0004 — Pattern draft struct pour éditer les `@Model`

**Date** : 2026-04-18
**Statut** : Accepté

## Contexte

Toute UI d'édition (deck, carte) doit permettre à l'utilisateur d'annuler ses modifications sans corrompre l'objet en base.

SwiftData a un comportement d'**autosave implicite** : toute mutation d'une propriété d'une instance `@Model` est potentiellement persistée (selon la `ModelContext` configuration). Si on fait `@Bindable var deck = existingDeck` dans un formulaire et qu'on relie les `TextField` à `$deck.name`, la frappe écrit directement dans l'objet SwiftData → Cancel ne peut plus annuler.

Trois options :

- **`@Bindable` direct sur l'objet SwiftData** — simple, mais impossible d'annuler proprement
- **Snapshot / rollback** — garder les valeurs originales, les restaurer en Cancel. Fragile, oublier un champ = bug silencieux
- **Draft struct value-type** — représentation en struct Swift, commit explicite au Save

## Décision

Utiliser une **struct Equatable value-type** pour chaque formulaire d'édition. Les types sont dans `Mémoire/Features/Editor/` :

```swift
struct DeckDraft: Equatable, Identifiable {
    let id: UUID
    var existingID: UUID?   // nil = création, sinon édition
    var name: String
    var isEditing: Bool { existingID != nil }
    var isValid: Bool { !name.trimmed.isEmpty }
    static func edit(_ deck: Deck) -> DeckDraft { ... }
}

struct CardDraft: Equatable, Identifiable {
    let id: UUID
    var existingID: UUID?
    var deckID: UUID
    var front: String
    var back: String
    ...
}
```

Le sheet d'édition (`DeckEditorSheet`, `CardEditorSheet`) :
- Reçoit un `DeckDraft` en `init`, le copie dans un `@State private var draft`
- Les `TextField` sont reliés à `$draft.name` — écritures locales uniquement
- **Au Save** : lookup via `FetchDescriptor<Deck>(predicate: #Predicate { $0.id == existingID })`, puis update des champs ou `context.insert(Deck(name: draft.trimmedName, ...))`, puis `try context.save()` dans un `do/catch`
- **Au Cancel** : dismiss. Zéro modification persistée.

Le `Binding(get:set:)` custom dans le callsite a été banni (causait un timeout du type-checker Swift sur les sheets). Le pattern actuel :

```swift
.sheet(item: $editingDeck) { draft in
    DeckEditorSheet(initialDraft: draft)
}
```

Le sheet possède son propre `@State`, initialisé depuis le param.

## Conséquences

**Positives** :
- Annulation triviale : rien n'est persisté tant que Save n'est pas tapé
- Type checker Swift respiré : pas de `Binding(get:set:)` complexe à inférer
- Testable : on peut instancier un `DeckDraft`, simuler des modifications, vérifier la logique sans `ModelContext`
- Même sheet sert création + édition (détecté via `existingID != nil`)

**Négatives** :
- Duplication : les champs du `@Model` sont recopiés dans le draft. Acceptable pour des formulaires courts (2-3 champs par modèle)
- Pattern à apprendre pour les contributeurs. Mitigation : ce document + exemples dans `Features/Editor/`

## Alternatives considérées

- **`@Bindable` direct sur `@Model`** — rejeté : perd le Cancel
- **Snapshot / rollback via `context.rollback()`** — rejeté : rollback SwiftData agit sur tout le context, pas juste l'objet en cours, peut annuler d'autres modifications légitimes
- **`Binding(get:set:)` custom dans `.sheet` closure** — rejeté : provoque un timeout du type-checker Swift sur les sheets avec plusieurs niveaux de binding imbriqués (documenté dans le bug tracking interne de la session)
