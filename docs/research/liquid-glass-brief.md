# Mémoire × Liquid Glass : adoption sélective et chrome-only

**Verdict : adoption SÉLECTIVE.** Liquid Glass doit équiper uniquement la **couche de navigation** de Mémoire (tab bar, toolbar, sheets, bouton CTA paywall, menu des boutons de notation FSRS) — jamais la carte de révision, jamais le canvas éditorial New York, jamais les listes de decks. Cette stratégie est techniquement alignée sur la propre doctrine d'Apple (« reserved for the navigation layer that floats above content ») et protège à la fois l'identité *calm luxury*, le contrat WCAG AAA 15:1 que vous visez et les utilisateurs TDAH/photophobes. **iOS minimum recommandé : 18.0** (≈ 90 % de la base installée couverte, 34 points de plus qu'un ciblage iOS 26), avec *progressive enhancement* via `if #available(iOS 26.0, *)`. Ne pas activer l'opt-out `UIDesignRequiresCompatibility` : Apple l'a annoncé comme **supprimé dans iOS 27** (fenêtre estimée Q4 2026/Q1 2027) — autant embrasser la trajectoire dès la v1.0, mais dans sa forme restreinte que la communauté désigne désormais comme *« less glass = premium »*.

Le reste du rapport détaille la preuve factuelle, les tokens à ajouter, les patterns SwiftUI, les risques, et liste 18 actions concrètes à injecter dans le CDC v1.2.

---

## 1. Fondamentaux Liquid Glass et trajectoire Apple depuis WWDC 2025

Apple positionne Liquid Glass non comme un flou gaussien (ancien `UIBlurEffect` / `Material.ultraThinMaterial`) mais comme un **méta-matériau dynamique** qui *réfracte* la lumière en temps réel via lentille optique simulée, ajoute des *highlights spéculaires* pilotés par le gyroscope et peut *morpher* entre formes. Trois principes directeurs sont énoncés dans la HIG mise à jour : **Hiérarchie** (le chrome s'élève, ne se confond pas avec le contenu), **Harmonie** (alignement concentrique matériel/logiciel), **Consistance** (iOS 26, iPadOS 26, macOS Tahoe 26, watchOS 26). La doctrine Apple clé, répétée dans la session WWDC « Meet Liquid Glass » (session 219) et la HIG Materials : **« Liquid Glass is best reserved for the navigation layer that floats above the content of your app »** — ne jamais l'appliquer au contenu (listes, tables, médias, texte long).

Le type public `Glass` en SwiftUI expose trois variantes seulement : **`.regular`** (matériau frosté par défaut, adaptatif — à utiliser pour 95 % des cas), **`.clear`** (haute transparence, réservé aux fonds médias très chargés où le *lensing* doit dominer — à **bannir** de Mémoire) et **`.identity`** (off conditionnel). Deux modificateurs s'y composent : `.tint(Color)` et `.interactive()`. Les API SwiftUI associées sont `.glassEffect(_:in:isEnabled:)`, le conteneur `GlassEffectContainer(spacing:)` qui permet aux éléments de glass de se refléter mutuellement et de morpher, `.glassEffectID(_:in:)` pour les transitions de forme, `.glassEffectUnion(id:namespace:)`, `.glassEffectTransition(_:)`, les boutons styles `.glass` et `.glassProminent`, le `.backgroundExtensionEffect()` (pour étendre une image sous une sidebar) et la nouvelle hiérarchie d'outils de toolbar (`ToolbarSpacer(.fixed/.flexible)`, `DefaultToolbarItem(kind: .search, placement: .bottomBar)`). Point crucial pour l'estimation d'effort : **recompiler avec Xcode 26 suffit à obtenir automatiquement le chrome Liquid Glass** sur tab bar, toolbar, sheets et menus — environ 80 % du gain visuel est « gratuit ».

**Évolution 26.0 → 26.4, instructive pour votre décision.** La bêta 1 de juin 2025 a subi une critique massive pour translucidité excessive (comparaisons Windows Vista, Gruber, Mantia). Apple a **reculé en trois temps** : bêta 3 juillet 2025 (TechCrunch titre « Diluted Glass », opacité fortement augmentée sur Music, Safari, Notifications, Settings) ; **iOS 26.1** le 3 novembre 2025 a ajouté dans Réglages > Luminosité une bascule utilisateur « Clear / **Tinted** » (plus opaque, légèrement désaturée, ne nécessite pas d'activer l'accessibilité) ; **iOS 26.2** le 12 décembre 2025 a introduit un *slider d'opacité par police* pour l'horloge d'écran verrouillé ; **iOS 26.4** fin mars 2026 a ajouté le toggle **« Reduce Bright Effects »** dans Accessibility > Display & Text Size pour atténuer les flashs lumineux des boutons/claviers (source : 9to5Mac, 10 avril 2026). Traduction stratégique : **Apple a lui-même acté que le Liquid Glass tel qu'il l'avait imaginé à WWDC était trop lumineux et trop contrasté-faible**. La direction 2026 est « less glass » — Mantia, Gruber et Flarup l'ont théorisée, Apple l'a matérialisée.

Deux mouvements RH confirment la tendance : **Alan Dye (SVP Design software) a quitté Apple pour Meta le 3 décembre 2025**, remplacé par **Stephen Lemay** (26 ans chez Apple, décrit par Gruber comme « la meilleure nouvelle personnel en décennies ») ; **Sebastiaan de With (Halide/Lux) rejoint l'équipe HI Design d'Apple le 28 janvier 2026**, lui dont le concept « Living Glass » publié à WWDC était précisément la version *retenue* de Liquid Glass que beaucoup auraient voulu voir shipper.

## 2. Accessibilité, TDAH, photophobie et contraste AAA : le verdict technique

**WCAG AAA 15:1 est structurellement incompatible avec toute surface Liquid Glass.** C'est la conclusion convergente de trois audits sérieux : l'**Infinum Accessibility Audit** (Ana Šekerija, 12 juin 2025) mesure des ratios aussi bas que **1,5:1** sur des écrans par défaut, contre 4,5:1 pour AA ; le **Nielsen Norman Group** (Raluca Budiu, « Liquid Glass Is Cracked », 10 octobre 2025) documente des échecs de lisibilité dans Apple Maps, Safari, Mail et Messages ; l'**AppleVis 2025 Vision Accessibility Report Card** (publié mars 2026) fait chuter la note d'Apple de 0,2 point à 3,7/5, les utilisateurs malvoyants rapportant un « impact négatif significatif ». Un matériau translucide qui compose au-dessus d'un contenu imprédictible ne peut **par construction** garantir un contraste supérieur à 4,5:1, encore moins 7:1 ou 15:1. **Conséquence directe pour Mémoire : le texte principal (flashcards, contenu éditorial, métadonnées critiques) doit impérativement vivre sur surface opaque.** Le glass est réservé aux éléments décoratifs/chrome où l'échec partiel de contraste est acceptable car redondamment signalé (icônes SF Symbols avec label visible ailleurs, boutons avec état focus).

**Le fallback automatique d'Apple est réel mais incomplet.** Quand l'utilisateur active Réglages > Accessibilité > *Réduire la transparence*, `.glassEffect()` bascule automatiquement vers un matériau plus frosté et plus opaque — sans que vous écriviez de code. MacRumors décrit le comportement : « makes translucent areas more opaque while maintaining the overall iOS 26 aesthetic » — autrement dit, **pas complètement opaque**. Dedoimedo documente des résidus de translucidité sur lock screen et dock même avec le réglage activé. Pour viser AAA 15:1, il faut donc un **fallback explicite via `@Environment(\.accessibilityReduceTransparency)`** qui remplace tout `.glassEffect()` par un fond solide `#2A2A2C` (token `surface.raised`). De même, « Augmenter le contraste » ajoute des bordures contrastantes mais ne force pas l'opacité totale : les deux réglages doivent être combinés.

**Photophobie (69 % des adultes TDAH, Kooij & Bijlenga 2014) : risque amplifié.** Liquid Glass cumule trois propriétés documentées comme triggers photophobiques : *lensing* en temps réel (concentration de lumière), *specular highlights* qui suivent le gyroscope (lumière qui bouge sur l'écran immobile), et *bright flashing feedback* sur pression de boutons et clavier. La littérature sur la migraine (Noseda et al., PMC8497413) montre que l'inconfort ne dépend pas que de la luminance absolue mais des motifs, flickers et transitions haute-contraste — exactement ce que Liquid Glass introduit par design. Les rapports utilisateurs convergent : thread Apple Community #256187278 (plusieurs dizaines de témoignages de céphalées, vertiges, incapacité d'usage), TechRadar « eye strain and vertigo », Phandroid « vertigo and eye strain in Dark Mode », Gizmodo qui décrit l'effet *Café-Wall illusion* sur le glow des icônes. Apple a partiellement répondu avec **Reduce Bright Effects** en 26.4 (avril 2026). **Implication pour Mémoire** : vous devez shipper dès v1.0 un **toggle in-app « Mode Calme »** qui court-circuite toute surface glass, désactive `.interactive()` et force le matériau solide — et non dépendre des seuls réglages système, car un utilisateur TDAH sensible à la lumière qui télécharge votre app ne va pas naviguer dans Accessibility avant d'essayer une flashcard.

**Reduce Motion + Liquid Glass : partiellement géré.** La session WWDC 219 confirme qu'activer Reduce Motion « disables any elastic properties » — morphing de formes, bubbling des tab bars, animations de sélection élastiques. **Ce qui reste actif** : les highlights spéculaires (rendus continus, dépendants du gyroscope) et certains fades. Ces effets ne sont **totalement supprimés qu'avec Reduce Bright Effects en iOS 26.4**, pas avec Reduce Motion seul. Le Neurodiversity Design System (neurodiversity.design) et les travaux de Stéphanie Walter (stephaniewalter.design) convergent sur : prédictibilité, réduction du bruit visuel, contrôle utilisateur de la stimulation — **trois principes sapés par les tab bars qui se collapsent au scroll, les boutons qui shimmerent et les surfaces qui flippent light/dark mid-scroll**. Pour une app TDAH avec principe *un écran = une action*, ces animations doivent être désactivées au niveau de votre code, pas seulement au niveau système.

**Études sur charge cognitive et TDAH**, sans être spécifiques à Liquid Glass, apportent un étayage : Mihaylova et al. (PMC9620686) montrent que les participants TDAH bénéficient moins de l'information visuelle en présence de bruit visuel externe ; Lydon-Staley et al. (PMC10727773) distinguent *perceptual load* (parfois bénéfique aux TDAH pour le filtrage) de *cognitive load* (délétère). Liquid Glass ajoute surtout du *cognitive load* (parser des contrôles qui se superposent au contenu, deviner les affordances qui changent au scroll) et non du *perceptual load* utile. Verdict NN/G : « Carousel dots quietly morph into the word Search… Tab bars bubble and wiggle… buttons briefly pulsate » — ce qu'ils qualifient d'attention-hijacking permanent. **Pour Mémoire, c'est exactement le profil d'usage qu'il faut éviter sur les écrans de révision, où le coût cognitif doit être réservé à la tâche (rappel actif).**

## 3. Mariage Liquid Glass × or #D4AF37 × dark mode calm luxury

**Le comportement des couleurs sur glass est antagoniste aux teintes métalliques.** Apple décrit le tinting comme « inspired by how colored glass works in reality: changing hue, brightness and saturation depending on what's behind » — concrètement, **le système remappe votre couleur de marque en gradient luminance-dépendant, les tons saturés et métalliques perdent leur chroma**. L'or repose photographiquement sur un *gradient* plus un *specular highlight* ; Liquid Glass ayant déjà son propre éclairage spéculaire, appliquer `.tint(Color("D4AF37"))` à une tab bar produit un **aplat jaune-brun** et non un éclat de laiton. Louie Mantia dans « Rose-Gold-Tinted Liquid Glasses » le formule sèchement : « whatever Liquid Glass seems to be, it isn't what many of us were hoping for ». La solution n'est pas de forcer l'or sur glass — c'est de **garder l'or sur le solide** et laisser le chrome glass neutre.

Les chiffres de contraste sont cependant rassurants sur le solide : `#D4AF37` sur `#1C1C1E` donne un ratio **≈ 8,6:1**, supérieur à AAA 7:1 pour texte normal (AAA-enhanced 15:1 reste réservé au blanc cassé `#F2F2F7` sur `#1C1C1E` : ≈ 15,3:1). Sur glass `.regular` en dark mode, la couche de dimming ajoute ≈ 10–20 % de luminance au fond effectif et désature le texte : l'or tombe autour de 5:1, toujours AA mais plus AAA.

**Dark mode est l'environnement le plus favorable à Liquid Glass** — consensus solide. Thomas Fitzgerald (blog.thomasfitzgeraldphotography.com) : « dark mode looks better when it comes to the glass elements. Better consistency across the elements, and they're not as in your face ». La session WWDC 219 (Shubham) confirme que les petits éléments de glass « flip from light to dark, so the material is discernible ». Trois raisons techniques : le *lensing* contraste mieux contre du quasi-noir `#1C1C1E` que contre de la photo brillante ; la couche de dimming est invisible dark-on-dark ; et surtout, vous **évitez le failure mode #1 de Liquid Glass** qui est la lisibilité sur wallpapers bariolés — Mémoire n'a par nature pas de fond photo. Faites de Mémoire une app **dark-first** (un switch light mode optionnel en v1.2, mais pas une priorité MVP).

**Typographie éditoriale sur glass : règle stricte.** Apple n'interdit pas les serifs mais chaque démo WWDC utilise SF Pro sur le chrome. Pimp My Type (« Apple's Liquid Glass Shatters Typography ») mesure que la vibrancy treatment appliquée automatiquement par le système **amincit les pleins et déliés des sérifs** — New York perd ses terminals, ses brackets, son contraste. Michael Rafailyk (Medium, mars 2026) : « small elements can lose contour ». **Règle pour Mémoire : New York n'apparaît QUE sur surface solide** (canvas de révision, détails de flashcard, citations, drop caps, pull quotes). SF Pro gère tout le chrome glass, avec un **bump de poids systématique** (Regular → Medium, Medium → Semibold) pour compenser la vibrancy qui affine les traits.

**Patterns concrets de convivialité calm luxury + glass, directement exploitables :**

| Élément | Surface | Typographie | Usage de l'or |
|---|---|---|---|
| Tab bar (bottom) | `glass.regular` | SF Pro 11 Medium | Point solide or sur la couche contenu sous l'onglet actif, **jamais** tint or de la barre |
| Toolbar nav | `glass.regular` | SF Pro 17 Semibold | Icônes blanches/primary uniquement |
| CTA primaire paywall / « Commencer la révision » | `glass.prominent` + `.tint(goldOnGlass)` | SF Pro 17 Semibold | Seul endroit où l'or teinte le glass |
| Carte flashcard (recto/verso) | **Solide** `surface.elevated` | New York 18–28 | Hairline or 0,5 pt optionnel |
| Boutons FSRS (Again/Hard/Good/Easy) | `GlassEffectContainer` + `.glassEffect(.regular)` par bouton | SF Pro 15 Semibold | Tinte sémantique rouge/orange/vert/bleu — **pas d'or** |
| Sheet modal (import deck, paramètres) | **Solide** `surface.raised` | New York + SF Pro | Or sur divider horizontal, pas sur fond |
| Onboarding | Glass acceptable car fond brand | SF Pro Semibold 17+ | Accent or sur logo/icône uniquement |
| Stats FSRS (heatmap) | Toolbar glass / chart solide | SF Pro 13 | Courbes en or solide |

Le *token set* à ajouter au design system de Mémoire doit dédoubler l'or : `gold.solid = #D4AF37` pour le solide, et `gold.onGlass = #E6C558` (pré-éclairci pour survivre à la vibrancy) pour le cas unique du `.glassProminent`. Pattern de référence tiré du GoodLinks macOS (featured dans la gallery Apple) et de Matter (read-later, gallery Apple) : *« rebuilt with Apple's Liquid Glass… all native components for a cleaner, more cohesive look that lets your content shine »*. Les deux apps incarnent exactement la doctrine recommandée pour Mémoire : **chrome glass, contenu solide, typographie éditoriale intacte.**

## 4. Retours terrain : qui a réussi, qui a raté, et la tendance 2026

**Adoptions réussies bien documentées** : OmniFocus 4.8 (collapsing Perspectives Bar — featured dans la Apple gallery), Drafts 5 (Viticci : « pairs well with Drafts' UI »), Widgetsmith 8 (David Smith, « has never looked better »), Flighty (redesign synchronisé avec 26.1), Sequel (Viticci : « one of the nicest implementations… doesn't sacrifice information or legibility »), Things 3.22, Fantastical, Carrot Weather, GoodLinks, Raycast (adoption *sélective* : glass seulement sur AI Chat macOS, pas tout le reste). Apple a publié en **avril 2026 une nouvelle Liquid Glass Developer Gallery** (developer.apple.com/design/new-design-gallery-2026/) listant comme exemplaires : CNN, Crumbl, OmniFocus, Slack, Lowe's, American Airlines, Sky Guide, Lucid, AllTrails, Fantastical, Trello, Le Monde, Tasks, GoodLinks, Denim. Les Apple Design Awards 2025 ont été annoncés **avant** la WWDC et donc avant Liquid Glass : aucun lauréat n'a été récompensé *pour* Liquid Glass, les ADA 2026 ne sont pas encore tombés.

**Adoptions prudentes ou refusées** : Bear a publiquement communiqué (community.bear.app, septembre 2025) : « We want to bring the Liquid Glass feel while keeping the original iconic style » — toujours en cours en avril 2026 ; Obsidian, Notion, 1Password — **skip** (Electron, dépendance upstream) ; Anki, Quizlet, iA Writer, Ulysses — **skip** en avril 2026 (aucun travail visible) ; même **iWork d'Apple (Pages, Numbers, Keynote), Final Cut Pro, iMovie** n'avaient pas été mis à jour en septembre 2025, Apple elle-même traînant sur son propre design system.

**Critiques professionnelles influentes**. John Gruber signe « Bad Dye Job » (daringfireball.net, décembre 2025) : « Dye's decade-long stint running Apple's software design team has been, on the whole, terrible ». L'épisode **The Talk Show #428** (Gruber + Mantia, 31 juillet 2025) est devenu référentiel — trois heures de critique du Liquid Glass, décrit par Gruber fin 2025 comme « probablement mon épisode préféré de l'année ». Louie Mantia publie coup sur coup « Rose-Gold-Tinted Liquid Glasses » et « A Responsibility to the Industry » (lmnt.me) — réquisitoire contre la direction prise. Federico Viticci (MacStories) opère un **retournement notable** : en juillet 2025 « the entire idea of Liquid Glass needs to be scrapped », puis en septembre 2025 après review de 70 apps tierces : « more than meets the eye… I'd rather see Apple take big, imperfect swings than stand still » ; sur 26.1 Tinted : « given the readability issues… this change is a good one ». Michael Flarup signe « Through The Liquid Glass » : « With Liquid Glass, iOS gains personality and macOS loses some of its soul » — takeaway nuancé, célèbre la direction mais critique l'exécution. L'ATP (épisodes 644 et 672) forge la formule désormais citée : **« Don't Liquid Glass All the Things »**.

**Tendance 2026 en design iOS premium/calm/editorial : dichotomie claire.** Canva 2026 Design Trends Report identifie une bifurcation : **« Opt-Out Era »** (serifs, palettes pared-down, layouts éditoriaux structurés, anti-cuteness — recherches Canva pour « clean layout », « serif », « simple branding » en hausse de 54 % YoY) **d'un côté**, et **« Texture Check »** (surfaces glassy, tactiles, waxy, tirée par Apple Liquid Glass) de l'autre. Orizon liste « Calm design becomes a competitive advantage » dans les 10 tendances 2026 aux côtés de Liquid Glass. Consensus dans les synthèses Zignuts/asappstudio/designmonks : Liquid Glass convient à *luxury, media, AI* ; pour *productivité/éducatif/clarity-first*, **les designs plus simples et solides fonctionnent mieux**. L'arrivée de Lemay + de With chez Apple est largement anticipée (Gruber, Numeric Citizen, Tsai) comme un **adoucissement du Liquid Glass en iOS 27** — pas un rollback mais un rééquilibrage vers la lisibilité. **Mémoire, app d'apprentissage premium adulte, est exactement dans la catégorie où la recherche suggère la restraint comme signal de qualité.**

## 5. iOS minimum, adoption et implémentation technique

**iOS 26 en avril 2026 : ~66 % de la base installée iPhone globale** selon les données officielles Apple publiées le 12 février 2026 (74 % des iPhones des 4 dernières années, 66 % de tous les iPhones actifs, 57 % de tous les iPads). TelemetryDeck (échantillon indie, adopters plus rapides) mesure 78,98 % fin mars 2026, iOS 18 à 16 %, iOS 17 et antérieurs résiduels. La pseudo-crise Statcounter (15 % en janvier 2026) a été publiquement reconnue comme un bug de détection par Statcounter lui-même. **Recommandation iOS minimum pour Mémoire : iOS 18.0.** Rationnel : (a) iOS 18+ couvre ≈ 90 % des iPhones actifs (66 % iOS 26 + 24 % iOS 18) ; (b) cibler iOS 26 exclut ≈ 34 % du marché adressable — trop agressif pour un abonnement payant en 2026 ; (c) redescendre à iOS 17 ajoute ≈ 5 % de portée mais double la surface `#available` et prive de `#Expression` predicates, `#Index`, custom data stores et du fix de la régression mémoire `.externalStorage`/`.count` de SwiftData iOS 18 ; (d) iOS 18 + progressive enhancement iOS 26 est la stratégie retenue par l'app **Grow** (Editor's Choice, 173 pays), explicitement documentée : *« Maintain user experience for users on older iOS versions unchanged; bring refreshing visuals to users upgrading to iOS 26 »*.

**Deadline calendrier critique** : depuis le **28 avril 2026**, Apple impose le **SDK iOS 26 + Xcode 26** pour toute soumission ou mise à jour App Store (developer.apple.com/news/upcoming-requirements/, thread Apple Developer 806141). Votre MVP shippant en mai-juin 2026 sera donc obligatoirement buildé avec Xcode 26.3 ou 26.4 sur le SDK iOS 26 — la *deployment target* reste libre à iOS 18. **N'utilisez pas** l'opt-out `UIDesignRequiresCompatibility = YES` : Apple l'a confirmé comme supprimé en iOS 27 (automne 2026), l'adopter serait une dette technique à courte durée de vie.

**Pattern SwiftUI de référence — modificateur adaptatif** (dérivé de LiquidGlassReference/conorluddy et Sanjay Nelagadde, Level Up Coding) :

```swift
extension View {
    @ViewBuilder
    func memoireSurface<S: Shape>(
        in shape: S = .rect(cornerRadius: 16),
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            // Respect Reduce Transparency via environment
            self.modifier(GlassOrSolid(shape: shape, tint: tint, interactive: interactive))
        } else {
            self.background(Color("surface.raised"), in: shape)
        }
    }
}

@available(iOS 26.0, *)
struct GlassOrSolid<S: Shape>: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    let shape: S; let tint: Color?; let interactive: Bool
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color("surface.raised"), in: shape)
        } else {
            var glass: Glass = .regular
            if let tint { glass = glass.tint(tint) }
            if interactive { glass = glass.interactive() }
            return AnyView(content.glassEffect(glass, in: shape))
        }
    }
}
```

**Performance sur iPhone 11–13 non-Pro** : Apple Community thread 256138201, MacObserver, BGR documentent lag de scroll, stutter clavier, jank UI sur A13–A14 après upgrade iOS 26. Les tests contrôlés de MacRumors (24 octobre 2025) sur iPhone 17 Pro Max ne montrent **aucune différence de batterie** entre Clear / Tinted / Reduce Transparency — le coût est GPU/thermique, pas énergétique, et il se concentre sur les chipsets A13–A14. **Testez impérativement Mémoire sur iPhone 12 mini ou 13 avant MVP**. Règles à enforcer : un seul `GlassEffectContainer` par écran, pas de glass imbriqué, glass réservé au chrome (pas aux rows de liste — anti-pattern illustré par Donny Wals).

**Estimation d'effort pour Mémoire** (MVP 5–7 semaines, SwiftUI-native, app neuve donc pas de legacy à stripper) : recompile Xcode 26 → 2–3 jours (80 % du rendu Liquid Glass gratuit sur tab bar, toolbar, sheets) ; modificateur adaptatif + glass FSRS buttons + CTA paywall glassy → +3–5 jours ; `GlassEffectContainer` morphing + tabViewBottomAccessory streak bar → +1 à 1,5 semaine. **Budget raisonnable total : 1 semaine de travail Liquid Glass** dans votre planning 5–7 semaines, le reste de la « polish tier » repoussé en v1.1.

## 6. Risques à anticiper

**Risque #1 — Utilisateurs TDAH photophobes abandonnant au premier écran.** Mitigation : Mode Calme in-app toggle (non dépendant des réglages système), par défaut activé pour les nouveaux utilisateurs qui cochent une case « sensibilité visuelle » dans l'onboarding.

**Risque #2 — Échec AAA 15:1 sur surfaces glass.** Mitigation : architecture chrome-glass / contenu-solide ; aucun texte de flashcard ou métadonnée critique ne vit sur glass ; audit Xcode Accessibility Inspector systématique avant chaque release.

**Risque #3 — Lag sur iPhone 11–13.** Mitigation : test device physique obligatoire ; désactivation de `.interactive()` par défaut ; `scrollEdgeEffectStyle(.hard, for: .bottom)` sur l'écran de révision.

**Risque #4 — Dérive design vers le chrome glass partout.** Mitigation : règle d'or dans le design system documentée en v1.2 : *« un seul élément glass par écran, jamais sur carte ou contenu, jamais `.clear` »*.

**Risque #5 — Dépendance à une direction design Apple encore mouvante.** iOS 26.1 Tinted, 26.2 slider, 26.4 Reduce Bright Effects, arrivée de Lemay + de With : la trajectoire iOS 27 (WWDC 2026, 8–12 juin) modifiera Liquid Glass. Mitigation : tokens de design system abstraits (`surface.glass.regular` vs `.glassEffect(.regular)` en dur), modificateur `memoireSurface` centralisé, facile à repiquer.

**Risque #6 — Support Xcode 27 / iOS 27.** Apple retirera `UIDesignRequiresCompatibility` ; les apps qui ont opt-out seront forcées d'adopter. Mitigation : adopter dès v1.0 dans la forme restreinte recommandée → zéro dette technique, zéro panique de fin 2026.

**Risque #7 — Bug Liquid Glass rendant Mémoire inutilisable ponctuellement** (ex. Menu dans GlassEffectContainer en 26.0–26.1, artefacts `.glassProminent` + `.circle`). Mitigation : éviter les combinaisons bugguées listées dans LiquidGlassReference, cibler iOS 26.2+ pour les fonctionnalités glass avancées (`@available(iOS 26.2, *)` sur les morphings complexes).

## 7. Décision finale argumentée

La question n'est pas *si* adopter Liquid Glass mais *quelle dose*. Quatre options ont été pesées :

**Full embrace (rejeté).** Violerait AAA 15:1 sur les zones éditoriales, déstabiliserait les utilisateurs TDAH/photophobes, laverait le gold `#D4AF37` en aplat jaune sur le chrome, contredirait la doctrine Apple elle-même (« navigation layer only ») et s'aligne sur la trajectoire 2025 qu'Apple corrige depuis iOS 26.1.

**Skip total (rejeté).** Requerrait `UIDesignRequiresCompatibility` qui sera supprimé en iOS 27 (automne 2026) — donc dette à 6 mois ; priverait Mémoire du polish natif gratuit du chrome qui signe « app 2026 premium » ; ferait paraître l'app datée aux yeux de votre segment (adultes TDAH, souvent early adopters, attentifs aux signaux de qualité iOS).

**Minimal (rejeté comme option finale).** Acceptable mais sous-exploite 80 % du gain « gratuit » (toolbar, tab bar, sheets qui passent automatiquement en glass au simple recompile Xcode 26). Laisser ce bénéfice sur la table sans raison identitaire forte n'a pas de sens.

**Sélectif (retenu).** Adopter Liquid Glass sur la **couche de navigation uniquement** — tab bar, toolbar, sheets, CTA paywall, menu des 4 boutons FSRS. Garder **solide** tout le reste : carte de révision, canvas éditorial New York, listes de decks, mode focus, modales de paramètres. Variante `.regular` exclusivement, jamais `.clear`. Dark mode first. Fallback Reduce Transparency explicite. Toggle Mode Calme in-app. Gold dédoublé en `gold.solid` / `gold.onGlass`. Ce choix est techniquement aligné sur la HIG Apple, philosophiquement aligné sur la tendance 2026 *« less glass = premium »* incarnée par Matter, GoodLinks, Fantastical, Raycast et Bear, et éthiquement aligné sur votre mission TDAH/accessibilité.

## 8. Actions concrètes à injecter dans le CDC v1.2

1. **Ajouter une section §X.Y « Design System – Matériaux »** définissant les tokens : `surface.base #1C1C1E`, `surface.elevated #232325`, `surface.raised #2A2A2C`, `surface.hairline #3A3A3C`, `surface.glass.regular`, `surface.glass.prominent`, `surface.glass.regular.fallback = surface.raised`.
2. **Dédoubler le token or** : `gold.solid = #D4AF37` (surfaces solides, sémantique primaire), `gold.onGlass = #E6C558` (unique usage : `.glassProminent` CTA paywall), `gold.muted = #A8892B` (états pressés), `gold.subtle = #D4AF37 @ 12%` (hairlines, washes).
3. **Fixer la règle chrome/contenu** dans le CDC en une ligne non négociable : *« Liquid Glass est réservé à la couche de navigation flottante (tab bar, toolbar, sheets, popovers, menus FSRS). Tout contenu éditorial — carte de révision, texte de rappel, métadonnées, listes de decks, paramètres — vit sur surface solide opaque. »*
4. **Bannir `.glassEffect(.clear)`** du code base et documenter l'interdiction.
5. **Cibler iOS 18.0 comme `IPHONEOS_DEPLOYMENT_TARGET`**, builder avec Xcode 26.3+ / SDK iOS 26, ne pas utiliser `UIDesignRequiresCompatibility`.
6. **Implémenter le modificateur `memoireSurface(in:tint:interactive:)`** comme unique point d'entrée des surfaces glass dans le code (pattern ci-dessus), gérant le fallback iOS 18 et `accessibilityReduceTransparency`.
7. **Ajouter un toggle « Mode Calme »** dans Réglages in-app (on par défaut pour utilisateurs ayant déclaré une sensibilité visuelle dans l'onboarding), qui force le fallback solide et désactive `.interactive()` globalement.
8. **Typographie stricte** : New York exclusivement sur surfaces solides ; SF Pro sur glass avec bump de poids systématique (Medium → Semibold, Regular → Medium) pour compenser la vibrancy.
9. **Dark mode first** ; light mode optionnel renvoyé en v1.2.
10. **Flashcards sur surface solide `surface.elevated`** avec ombre portée subtile, hairline or optionnelle ; boutons FSRS (Again/Hard/Good/Easy) dans un `GlassEffectContainer(spacing: 12)` avec tints sémantiques rouge/orange/vert/bleu, pas or.
11. **Paywall CTA unique zone où l'or teinte le glass** : `.buttonStyle(.glassProminent).tint(Color("gold.onGlass"))`.
12. **Onboarding** peut utiliser `.glassEffect(.regular.tint(.accentColor))` sur pastilles *Suivant/Passer* car fond brand contrôlé ; c'est l'unique écran où le glass-tint est acceptable au-delà du paywall.
13. **Respecter `accessibilityReduceMotion`** : désactiver `.interactive()`, désactiver animations `glassEffectID` de morphing ; n'utiliser `.matchedGeometry` que si ReduceMotion est off.
14. **Audit AAA 15:1 hebdomadaire** avec Xcode Accessibility Inspector + Colour Contrast Analyser sur tous les textes principaux, avec capture d'écran à chaque release ; viser 15,3:1 blanc cassé `#F2F2F7` sur `#1C1C1E`.
15. **Test physique obligatoire sur iPhone 12 ou 13 non-Pro** avant chaque release ; profil 120 Hz vs 60 Hz documenté.
16. **SwiftData** : modéliser le média des cartes en `@Relationship` et non en `.externalStorage`, utiliser `FetchDescriptor.fetchCount` et non `.count` sur relations (contourne la régression mémoire iOS 18.x).
17. **Accessibility Nutrition Labels** (nouveau App Store iOS 26) : remplir rigoureusement ; c'est un signal premium additionnel pour votre segment.
18. **Réserver 1 semaine dev Liquid Glass** dans le planning 5–7 semaines : 2–3 jours baseline (recompile + cleanup hacks hérités éventuels), 3–5 jours polish tier (modificateur, FSRS buttons, CTA paywall). Tier avancé (morphing choreography, tabViewBottomAccessory streak) → v1.1.

## Conclusion : la restraint comme signature

Le paradoxe apparent — adopter Liquid Glass tout en le contenant — est en réalité la posture la plus cohérente avec *calm luxury* et TDAH. Apple elle-même, via ses corrections 26.1/26.2/26.4 et ses embauches/départs de décembre 2025–janvier 2026, a validé ce que Mantia, Gruber et Flarup réclamaient dès juin 2025 : **moins de glass, plus de lisibilité, plus de sens par pixel**. Les apps qui ont le mieux réussi la transition (OmniFocus, Matter, GoodLinks, Sequel, Raycast sélectif) partagent toutes la même architecture : **chrome glass, contenu solide, typographie respirée**. Mémoire, app adulte d'apprentissage premium pour un public TDAH, est exactement dans la classe où la *restraint* n'est pas un compromis défensif mais **le signal premium lui-même**. Votre identité éditoriale New York + or + dark n'a pas à choisir entre modernité Apple 2026 et accessibilité AAA : elle doit simplement confiner la modernité à la bande de navigation et laisser respirer la matière éditoriale en dessous. C'est, structurellement, ce qu'Apple vous demande de faire depuis la première session WWDC 2025 — et c'est maintenant ce que la communauté design a fini par admettre publiquement.