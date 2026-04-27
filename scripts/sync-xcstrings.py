#!/usr/bin/env python3
"""Apply FR (source) + EN translations + CLDR plural rules to Localizable.xcstrings.

Usage:
    1. Build the project so Xcode regenerates the catalog from source extractions:
       xcodebuild -project Memoire.xcodeproj -scheme Memoire \\
           -destination 'generic/platform=iOS Simulator' build
    2. Open Localizable.xcstrings once in Xcode IDE — this triggers the editor's
       sync that merges new keys from .stringsdata into the catalog.
       (xcstringstool sync from the CLI also works if Xcode is unavailable.)
    3. Run this script:
       python3 scripts/sync-xcstrings.py
    4. Re-build to confirm the catalog still compiles.

Why this script exists:
    Apple's String Catalog editor in Xcode does not support bulk EN translations
    or programmatic CLDR plural rules. Maintaining ~250 strings + ~30 plurals by
    hand in the JSON is error-prone. This script is the single source of truth
    for FR -> EN mappings; new strings added in code go here first, then the
    script propagates them to the catalog.

When you add a new user-facing French string in code:
    - Add the FR -> EN pair to TRANSLATIONS, OR
    - Add the plural rule to PLURALS if it uses %lld card / %lld cards
    - Re-run this script.
"""
import json
from pathlib import Path

# Auto-detect the catalog relative to this script's location.
CATALOG_PATH = Path(__file__).resolve().parent.parent / "Memoire/Resources/Localizable.xcstrings"

# Direct FR -> EN translations for non-plural strings.
# Each key matches the extracted string from the build.
TRANSLATIONS = {
    # Empty / artifacts
    "": "",
    "·": "·",
    "M": "M",
    "Erreur": "Error",
    "Accueil": "Home",
    "%lld": "%lld",
    "/%lld": "/%lld",
    "%lld/40": "%lld/40",
    "%lldh": "%lld:00",
    "%lldj": "%lldd",
    # Brand kept identical
    "Mémoire": "Mémoire",
    "Mémoire 1.0": "Mémoire 1.0",
    "Quentin Aslan": "Quentin Aslan",
    # Rating
    "À revoir": "Again",
    "Connu": "Good",
    "Évident": "Easy",
    # HomeCopy salutations
    "Bonjour": "Good morning",
    "Bon après-midi": "Good afternoon",
    "Bonsoir": "Good evening",
    "Bonne nuit": "Good night",
    "À faire quand vous voulez.": "Take it when you want.",
    "Réviser": "Review",
    "Réviser une carte": "Review one card",
    "≈ 1 minute": "≈ 1 minute",
    "≈ 20 minutes ou plus": "≈ 20 minutes or more",
    # Greeting concatenation template
    "%@, %@.": "%1$@, %2$@.",
    "%@ · %lld cartes": "%1$@ · %2$lld cards",
    # Multi-arg strings without CLDR plural — by construction the calling code
    # only reaches these branches with the plural form (streak >= 2, total >= 2).
    "%lld jours d'affilée · %lld derniers jours": "%1$lld-day streak · last %2$lld days",
    "%lld / %lld cartes consolidées": "%1$lld / %2$lld cards consolidated",
    # HomeScreen
    "CARTE À RÉVISER": "CARD TO REVIEW",
    "CARTES À RÉVISER": "CARDS TO REVIEW",
    "Score de régularité": "Consistency score",
    # HomeCopy regularity (plural strings handled below)
    "1 jour d'affilée · %lld derniers jours": "1-day streak · last %lld days",
    # HomeCopy next review
    "Prochaine révision demain.": "Next review tomorrow.",
    "Prochaine révision dans une semaine.": "Next review in a week.",
    "Prochaine révision le %@.": "Next review on %@.",
    # CardDetailScreen kickers
    "Carte": "Card",
    # CardDetailScreen birthLabel
    "Apprise aujourd'hui": "Learned today",
    "Apprise hier": "Learned yesterday",
    "Apprise il y a 1 semaine": "Learned 1 week ago",
    "Apprise il y a 1 mois": "Learned 1 month ago",
    "Apprise il y a plus d'un an": "Learned more than a year ago",
    # CardDetailScreen nextReviewLabel
    "À ta prochaine session": "At your next session",
    "Disponible maintenant": "Available now",
    "Plus tard aujourd'hui": "Later today",
    "Demain matin": "Tomorrow morning",
    "Demain soir": "Tomorrow evening",
    "Dans %lld jours · %@": "In %1$lld days · %2$@",
    "La semaine prochaine": "Next week",
    "Dans plusieurs mois": "In several months",
    "L'an prochain": "Next year",
    # CardDetailScreen status words
    "À découvrir": "New to you",
    "En train de se former": "Building up",
    "Familière": "Familiar",
    "Ancrée": "Anchored",
    "À revoir bientôt": "Due soon",
    # CardDetailScreen insights — toDiscover
    "Tu vas la rencontrer bientôt.": "You'll meet it soon.",
    "Cette carte attend son premier tour.": "This card is waiting for its first turn.",
    "Première rencontre à venir.": "First encounter coming up.",
    # forming
    "Cette carte cherche encore son rythme.": "This card is still finding its rhythm.",
    "Elle revient souvent — c'est normal au début.": "It comes back often — that's normal at the start.",
    "Mémoire l'espace progressivement.": "Mémoire is gradually spacing it out.",
    # familiar
    "Tu retrouves cette carte sans effort. Elle tient bien.": "You recall this card effortlessly. It holds well.",
    "Elle revient maintenant à intervalle confortable.": "It now comes back at a comfortable interval.",
    "Cette carte a trouvé son rythme.": "This card has found its rhythm.",
    # anchored
    "Cette carte est solidement installée.": "This card is solidly settled.",
    "Tu peux compter sur elle longtemps.": "You can rely on it for a long time.",
    "Elle ne reviendra pas avant un bon moment.": "It won't return for quite a while.",
    # toReviewSoon
    "Mémoire la ramène pour toi cette semaine.": "Mémoire brings it back for you this week.",
    "Elle redemande un passage — rien de cassé.": "It needs another pass — nothing's broken.",
    "Cette carte demande une nouvelle visite.": "This card needs another visit.",
    # CardDetailScreen prochainPalierLine — segments
    "Si tu réponds ": "If you answer ",
    ", prochaine révision dans %@ au lieu de %@.": ", next review in %1$@ instead of %2$@.",
    # DeckDetailScreen
    "À réviser cette semaine · %lld": "To review this week · %lld",
    "Solidité moyenne · %@": "Average solidity · %@",
    "Voir le détail": "See details",
    "Réviser maintenant": "Review now",
    "Ce paquet est vide. Ajoute ta première carte.": "This deck is empty. Add your first card.",
    "Tout ce paquet est consolidé.": "This whole deck is consolidated.",
    "%lld / %lld": "%1$lld / %2$lld",
    "Aucune carte pour l'instant.": "No cards yet.",
    "+ Ajouter une carte": "+ Add a card",
    "Dessin": "Drawing",
    "Réponse dessinée": "Drawn answer",
    "NOUVELLE": "NEW",
    "À RÉVISER": "DUE",
    "PRÉVUE %@": "SCHEDULED %@",
    "Supprimer": "Delete",
    "Modifier": "Edit",
    # CompleteScreen
    "Terminer": "Done",
    "Ton paquet tient un peu mieux qu'hier.": "Your deck holds a little better than yesterday.",
    "Mémoire ramènera ces cartes pile avant que tu ne les oublies.": "Mémoire brings these cards back right before you forget them.",
    "Tu n'as rien à mémoriser de force — Mémoire programme le retour.": "Nothing to force-memorize — Mémoire schedules the return.",
    "Le travail invisible se passe entre les sessions.": "The invisible work happens between sessions.",
    "Plus tu reviens, plus l'espacement grandit.": "The more you come back, the wider the spacing grows.",
    "C'est l'écart entre les révisions qui fait la mémoire.": "It's the gap between reviews that builds memory.",
    "Ce que tu retrouves aujourd'hui tiendra plus longtemps.": "What you recall today will hold longer.",
    # ReviewScreen
    "Aucune carte à réviser": "No cards to review",
    "APPUYEZ POUR RÉVÉLER": "TAP TO REVEAL",
    "Double-tap pour noter cette carte.": "Double-tap to rate this card.",
    "Action irréversible": "Irreversible action",
    # NotificationScheduler
    "Vos révisions vous attendent": "Your reviews are waiting",
    "%@, vos révisions vous attendent": "%@, your reviews are waiting",
    "Quelques cartes aujourd'hui — 5 minutes suffisent.": "A few cards today — 5 minutes is enough.",
    # DecksScreen
    "Paquets": "Decks",
    "Aucun paquet pour l'instant.": "No decks yet.",
    "Créez votre premier paquet pour commencer.": "Create your first deck to get started.",
    "+ Créer un paquet": "+ Create a deck",
    "Créer un paquet": "Create a deck",
    "à jour": "up to date",
    # SettingsScreen
    "Heure du rappel": "Reminder time",
    "Nouvelles cartes / jour": "New cards / day",
    "Révisions": "Reviews",
    "Prénom (optionnel)": "First name (optional)",
    "Personnalise la salutation de l'accueil.": "Personalizes the home greeting.",
    "Mode Calme": "Calm Mode",
    "Désactive les effets translucides.": "Turns off translucent effects.",
    "Apparence & vous": "Appearance & you",
    "Exporter une sauvegarde": "Export a backup",
    "Restaurer une sauvegarde": "Restore a backup",
    "Sauvegarde": "Backup",
    "Exporte un fichier JSON contenant tes paquets, cartes et historique. La restauration remplace intégralement la base actuelle.": "Exports a JSON file containing your decks, cards, and history. Restoring replaces the current database entirely.",
    "Contacter ou signaler un bug": "Contact or report a bug",
    "À propos": "About",
    "Rejouer l'onboarding": "Replay onboarding",
    "Avancé": "Advanced",
    "Réglages": "Settings",
    "Restaurer la sauvegarde ?": "Restore the backup?",
    "Annuler": "Cancel",
    "Restaurer": "Restore",
    "Cette action remplace tous tes paquets, cartes et historique actuels. Elle est irréversible.": "This replaces all your current decks, cards, and history. It cannot be undone.",
    "OK": "OK",
    "Heure": "Time",
    # OnboardingFlow
    "Passer": "Skip",
    "Apprenez en profondeur, sans pression.": "Learn deeply, without pressure.",
    "On va faire connaissance.": "Let's get to know each other.",
    "Comment tu t'appelles ?": "What's your name?",
    "Ton prénom": "Your first name",
    "Le flip": "The flip",
    "Lisez la question, pensez à la réponse, puis appuyez pour vérifier.": "Read the question, think of the answer, then tap to check.",
    "Sensibilité visuelle": "Visual sensitivity",
    "Êtes-vous sensible aux lumières, reflets ou animations (migraine, photophobie) ?": "Are you sensitive to bright effects, reflections, or animations (migraine, photophobia)?",
    "Un rappel par jour": "One reminder a day",
    "Une notification à %lldh pour vos révisions.\nAucune pression.": "A notification at %lld:00 for your reviews.\nNo pressure.",
    "Autoriser les notifications": "Allow notifications",
    "Notifications autorisées": "Notifications allowed",
    "Notifications refusées": "Notifications denied",
    "Activez-les dans Réglages iOS si vous changez d'avis.": "Turn them on in iOS Settings if you change your mind.",
    "Deux mots à connaître": "Two words to know",
    "Mémoire mesure deux choses pour chaque carte.": "Mémoire tracks two things for each card.",
    "La solidité : à quel point un souvenir tient. Plus tu retrouves une carte, plus elle se solidifie.": "Solidity: how well a memory holds. The more you recall a card, the more solid it gets.",
    "La fraîcheur : la probabilité que tu t'en souviennes encore aujourd'hui. Quand elle baisse, Mémoire la ramène.": "Freshness: the probability that you still remember it today. When it drops, Mémoire brings it back.",
    "Tu n'as rien à régler.\nMémoire s'en occupe.": "Nothing to set up.\nMémoire takes care of it.",
    # DeckStatsSheet
    "Aujourd'hui": "Today",
    "Rien à revoir cette semaine.": "Nothing to review this week.",
    "Environ 1 carte à revoir cette semaine.": "About 1 card to review this week.",
    "Mémoire ne prédit pas plus loin que 7 jours — au-delà, c'est trop incertain.": "Mémoire doesn't predict beyond 7 days — past that, it's too uncertain.",
    # DeckEditorSheet
    "Vous ajouterez les cartes à l'étape suivante.": "You'll add cards in the next step.",
    "Enregistrer": "Save",
    "Créer": "Create",
    "NOM DU PAQUET": "DECK NAME",
    "Ex : Japonais, Histoire…": "E.g. Japanese, History…",
    "COULEUR": "COLOR",
    # CardEditorSheet
    "Effacer le dessin ?": "Clear the drawing?",
    "Effacer": "Clear",
    "Qu'est-ce que vous voulez mémoriser ?": "What do you want to memorize?",
    "La réponse à retenir…": "The answer to remember…",
    "Dessinez votre réponse": "Draw your answer",
    "Effacer le dessin": "Clear the drawing",
    # EmptyDueState
    "Journée terminée.": "Day complete.",
    "Revenez plus tard.\nPour le moment toutes vos cartes sont validées.": "Come back later.\nFor now all your cards are done.",
    "Toutes vos cartes sont à jour.\nRevenez demain pour poursuivre.": "All your cards are up to date.\nCome back tomorrow to continue.",
    "Votre cerveau consolide maintenant.\nLa pause fait partie de l'apprentissage.": "Your brain is consolidating now.\nThe pause is part of learning.",
    "Révision complète": "Review complete",
    # EmptyDecksState
    "Commencez par un\npremier paquet.": "Start with your\nfirst deck.",
    "Organisez vos cartes par sujet. Ajoutez des questions, laissez l'algorithme faire le reste.": "Organize your cards by topic. Add questions, let the algorithm do the rest.",
    # Widget
    "CARTES": "CARDS",
    "%lld / %lld révisées": "%1$lld / %2$lld reviewed",
    "À jour": "Up to date",
    "PROCHAINE": "NEXT",
    "Créez votre\npremier paquet": "Create your\nfirst deck",
    "Vos cartes à réviser, en un coup d'œil.": "Your cards to review, at a glance.",
    # DurationFormat
    "moins d'un jour": "less than a day",
    "1 jour": "1 day",
    "~1 semaine": "~1 week",
    "~2 semaines": "~2 weeks",
    "~3 semaines": "~3 weeks",
    "~1 mois": "~1 month",
    "~2 mois": "~2 months",
    "~3 mois": "~3 months",
    "~6 mois": "~6 months",
    "~1 an": "~1 year",
    "plus d'un an": "more than a year",
    # DeleteConfirmationSheet messages
    "Supprimer cette carte ?": "Delete this card?",
    "Supprimer ce paquet ?": "Delete this deck?",
    "« %@ » sera supprimée de façon irréversible.": "\"%@\" will be permanently deleted.",
    "« %@ » sera supprimé de façon irréversible.": "\"%@\" will be permanently deleted.",
    "« %@ » et sa carte seront supprimés de façon irréversible.": "\"%@\" and its card will be permanently deleted.",
    "Supprimer définitivement %@": "Permanently delete %@",
    "Supprimer définitivement %@ et sa carte": "Permanently delete %@ and its card",
    # EditorialSheet — footnote inverted in EN
    "Solidité": "Solidity",
    "La solidité, c'est combien de temps un souvenir tient avant qu'on doive le revoir.": "Solidity is how long a memory holds before it needs to be reviewed again.",
    "Quand tu retrouves une carte sans trop d'effort, sa solidité augmente — Mémoire l'espace alors davantage. Quand tu hésites, elle redescend, et la carte revient plus tôt.": "When you recall a card without much effort, its solidity goes up — Mémoire then spaces it out more. When you hesitate, it goes back down, and the card returns sooner.",
    "Tu n'as rien à régler. Mémoire s'en occupe.": "Nothing to set up. Mémoire takes care of it.",
    "En anglais : Stability": "In French: Solidité",
    "En anglais, on parle de « Stability » — c'est la même chose.": "In French, we say \"Solidité\" — it's the same thing.",
    "Fraîcheur": "Freshness",
    "La fraîcheur, c'est la probabilité que tu te souviennes encore d'une carte aujourd'hui.": "Freshness is the probability that you still remember a card today.",
    "Plus le temps passe sans révision, plus elle baisse. Quand elle descend trop, Mémoire ramène la carte avant que tu ne l'oublies vraiment.": "The longer you go without reviewing, the lower it gets. When it drops too far, Mémoire brings the card back before you actually forget it.",
    "On ne te montre pas un pourcentage qui descend en direct — ce serait du bruit. Mémoire s'en occupe en silence.": "We don't show you a live falling percentage — that would just be noise. Mémoire handles it quietly.",
    "Tu fais le rappel. Mémoire fait le calcul.": "You do the recall. Mémoire does the math.",
    "En anglais : Retrievability": "In French: Fraîcheur",
    "En anglais, on parle de « Retrievability » — c'est la même chose.": "In French, we say \"Fraîcheur\" — it's the same thing.",
}

# Strings that use CLDR plural variations (one/other in both FR and EN).
# Format: { "key": (fr_one, fr_other, en_one, en_other) }
PLURALS = {
    "%lld cartes": (
        "%lld carte", "%lld cartes",
        "%lld card", "%lld cards"
    ),
    "%lld cartes consolidées aujourd'hui.": (
        "%lld carte consolidée aujourd'hui.", "%lld cartes consolidées aujourd'hui.",
        "%lld card consolidated today.", "%lld cards consolidated today."
    ),
    "%lld cartes derrière toi.": (
        "%lld carte derrière toi.", "%lld cartes derrière toi.",
        "%lld card behind you.", "%lld cards behind you."
    ),
    "%lld cartes ont gagné en solidité aujourd'hui.": (
        "%lld carte a gagné en solidité aujourd'hui.", "%lld cartes ont gagné en solidité aujourd'hui.",
        "%lld card grew more solid today.", "%lld cards grew more solid today."
    ),
    "%lld cartes — tu peux refermer.": (
        "%lld carte — tu peux refermer.", "%lld cartes — tu peux refermer.",
        "%lld card — you can close the book.", "%lld cards — you can close the book."
    ),
    "%lld jours de régularité": (
        "%lld jour de régularité", "%lld jours de régularité",
        "%lld-day streak", "%lld-day streak"
    ),
    "%lld derniers jours": (
        "dernier jour", "%lld derniers jours",
        "last day", "last %lld days"
    ),
    "Apprise il y a %lld jours": (
        "Apprise il y a %lld jour", "Apprise il y a %lld jours",
        "Learned %lld day ago", "Learned %lld days ago"
    ),
    "Apprise il y a %lld mois": (
        "Apprise il y a %lld mois", "Apprise il y a %lld mois",
        "Learned %lld month ago", "Learned %lld months ago"
    ),
    "Aucune carte encore consolidée. %lld cartes en attente.": (
        "Aucune carte encore consolidée. %lld carte en attente.",
        "Aucune carte encore consolidée. %lld cartes en attente.",
        "No cards consolidated yet. %lld card waiting.",
        "No cards consolidated yet. %lld cards waiting."
    ),
    "Ces %lld cartes reviendront plus tard cette fois.": (
        "Cette carte reviendra plus tard cette fois.", "Ces %lld cartes reviendront plus tard cette fois.",
        "This card will come back later this time.", "These %lld cards will come back later this time."
    ),
    "Dans environ %lld mois": (
        "Dans environ %lld mois", "Dans environ %lld mois",
        "In about %lld month", "In about %lld months"
    ),
    "Dans environ %lld semaines": (
        "Dans environ %lld semaine", "Dans environ %lld semaines",
        "In about %lld week", "In about %lld weeks"
    ),
    "Environ %lld cartes à revoir cette semaine.": (
        "Environ %lld carte à revoir cette semaine.", "Environ %lld cartes à revoir cette semaine.",
        "About %lld card to review this week.", "About %lld cards to review this week."
    ),
    "Mémoire prolonge l'écart sur %lld cartes.": (
        "Mémoire prolonge l'écart sur %lld carte.", "Mémoire prolonge l'écart sur %lld cartes.",
        "Mémoire stretches the gap on %lld card.", "Mémoire stretches the gap on %lld cards."
    ),
    "Réviser %lld cartes": (
        "Réviser %lld carte", "Réviser %lld cartes",
        "Review %lld card", "Review %lld cards"
    ),
    "Session terminée. %lld cartes revues.": (
        "Session terminée. %lld carte revue.", "Session terminée. %lld cartes revues.",
        "Session complete. %lld card reviewed.", "Session complete. %lld cards reviewed."
    ),
    "Sur ces %lld cartes, ta mémoire répond bien.": (
        "Sur cette %lld carte, ta mémoire répond bien.", "Sur ces %lld cartes, ta mémoire répond bien.",
        "On this %lld card, your memory responds well.", "On these %lld cards, your memory responds well."
    ),
    "Tu as bouclé %lld cartes ce matin.": (
        "Tu as bouclé %lld carte ce matin.", "Tu as bouclé %lld cartes ce matin.",
        "You wrapped %lld card this morning.", "You wrapped %lld cards this morning."
    ),
    "Tu as bouclé %lld cartes ce soir.": (
        "Tu as bouclé %lld carte ce soir.", "Tu as bouclé %lld cartes ce soir.",
        "You wrapped %lld card this evening.", "You wrapped %lld cards this evening."
    ),
    "~%lld cartes": (
        "~%lld carte", "~%lld cartes",
        "~%lld card", "~%lld cards"
    ),
    "~%lld jours": (
        "~%lld jour", "~%lld jours",
        "~%lld day", "~%lld days"
    ),
    "Prochaine révision dans %lld jours.": (
        "Prochaine révision dans %lld jour.", "Prochaine révision dans %lld jours.",
        "Next review in %lld day.", "Next review in %lld days."
    ),
    "≈ %lld minutes": (
        "≈ %lld minute", "≈ %lld minutes",
        "≈ %lld minute", "≈ %lld minutes"
    ),
    # DeleteConfirmationSheet — multi-arg plural
    "« %@ » et ses %lld cartes seront supprimés de façon irréversible.": (
        "« %1$@ » et sa %2$lld carte seront supprimés de façon irréversible.",
        "« %1$@ » et ses %2$lld cartes seront supprimés de façon irréversible.",
        "\"%1$@\" and its %2$lld card will be permanently deleted.",
        "\"%1$@\" and its %2$lld cards will be permanently deleted."
    ),
    "Supprimer définitivement %@ et ses %lld cartes": (
        "Supprimer définitivement %1$@ et sa %2$lld carte",
        "Supprimer définitivement %1$@ et ses %2$lld cartes",
        "Permanently delete %1$@ and its %2$lld card",
        "Permanently delete %1$@ and its %2$lld cards"
    ),
    # HomeCopy ctaSubtitle — added after simplify review caught "1 cards" bug in EN.
    "%@ · %lld cartes": (
        "%1$@ · %2$lld carte", "%1$@ · %2$lld cartes",
        "%1$@ · %2$lld card", "%1$@ · %2$lld cards"
    ),
}


def main():
    if not CATALOG_PATH.exists():
        raise SystemExit(f"Catalog not found at {CATALOG_PATH}")

    catalog = json.loads(CATALOG_PATH.read_text())
    keys = list(catalog["strings"].keys())

    covered = set()
    missing = []

    for key in keys:
        entry = catalog["strings"][key]

        # Plurals come first (they share keys with TRANSLATIONS sometimes).
        if key in PLURALS:
            fr_one, fr_other, en_one, en_other = PLURALS[key]
            entry["extractionState"] = "manual"
            entry["localizations"] = {
                "fr": {
                    "variations": {
                        "plural": {
                            "one":   {"stringUnit": {"state": "translated", "value": fr_one}},
                            "other": {"stringUnit": {"state": "translated", "value": fr_other}}
                        }
                    }
                },
                "en": {
                    "variations": {
                        "plural": {
                            "one":   {"stringUnit": {"state": "translated", "value": en_one}},
                            "other": {"stringUnit": {"state": "translated", "value": en_other}}
                        }
                    }
                }
            }
            covered.add(key)
            continue

        # Direct FR -> EN
        if key in TRANSLATIONS:
            en = TRANSLATIONS[key]
            entry["extractionState"] = "manual"
            localizations = entry.setdefault("localizations", {})
            localizations["en"] = {
                "stringUnit": {
                    "state": "translated",
                    "value": en
                }
            }
            covered.add(key)
            continue

        missing.append(key)

    CATALOG_PATH.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n")

    print(f"Catalog:    {CATALOG_PATH}")
    print(f"Total keys: {len(keys)}")
    print(f"Covered:    {len(covered)}")
    print(f"Missing:    {len(missing)}")
    if missing:
        print("\nMissing translations (add to TRANSLATIONS or PLURALS in this script):")
        for k in missing:
            print(f"  {k!r}")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
