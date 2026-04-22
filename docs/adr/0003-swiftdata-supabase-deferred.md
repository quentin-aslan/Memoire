# ADR 0003 — SwiftData local-first, Supabase reporté V1.1

**Date** : 2026-04-18
**Statut** : Accepté

## Contexte

Le cahier des charges §7.2 spécifie Supabase comme backend final (remplace CloudKit pour portabilité, cross-platform vers future PWA, SQL familier, Sign in with Apple natif, Row-Level Security).

Trois options de temporalité :

- **Ship V1.0 avec Supabase sync + auth dès le départ** — ambitieux, ajoute 1-2 semaines de dev, requiert Sign in with Apple obligatoire
- **Ship V1.0 local-only, architecture prête pour sync** — MVP plus rapide, l'utilisateur peut tester sans compte
- **Ship V1.0 SwiftData + CloudKit** — natif Apple, mais remplacé ensuite → double travail

Le CDC §7.2 est explicite : « MVP sans sync. La couche Supabase sync est reportée en V1.1. Le MVP fonctionne en SwiftData local-only. »

## Décision

**SwiftData comme source de vérité locale. Supabase et auth reportés en V1.1.**

Les modèles `@Model` (Deck, Card, Review) contiennent **dès le V1.0** les champs de préparation sync définis dans le CDC §6.5 :

- `isDeleted: Bool`, `deletedAt: Date?` → soft delete, jamais hard delete
- `syncVersion: Int` → last-writer-wins
- `syncStatus: Int` (0=synced, 1=pendingCreate, 2=pendingUpdate, 3=pendingDelete, 4=failed)
- `id: UUID` partout (stable cross-device)

Ces champs sont écrits correctement dès maintenant (chaque save bump `syncVersion`, chaque delete passe `syncStatus = 3`) mais aucune couche sync ne les lit en V1.0. Ils « dorment » en base.

Quand V1.1 arrivera, une couche sync custom (~200-400 lignes d'après le CDC) lira ces champs pour synchroniser avec Supabase. **Zéro migration de données** requise.

Pas de Sign in with Apple en V1.0 — le CDC §7.2 indique « Sign in with Apple uniquement quand sync ajoutée ».

## Conséquences

**Positives** :
- MVP en 5-7 semaines au lieu de 6-8
- Utilisateurs peuvent tester sans créer de compte → levée de friction considérable
- Zéro coût backend pendant la phase MVP
- Architecture future-proof : passage à Supabase = ajout d'une couche, pas refonte

**Négatives** :
- L'app n'est pas multi-device en V1.0. Acceptable pour un MVP TDAH single-user focused
- Les champs sync non utilisés occupent de la place en base. Négligeable (4 Int + 2 Bool + 1 Date? par entité)
- Pas de backup cloud automatique en V1.0. Mitigation : export JSON local possible (à implémenter si demande utilisateur forte)

## Alternatives considérées

- **Supabase dès V1.0** — rejeté : ajoute complexité et délai, CDC explicite contre
- **CloudKit** — rejeté : remplacé par Supabase (raisons CDC §7.2 : cross-platform, SQL, portabilité pg_dump). Adopter CloudKit maintenant serait double travail
