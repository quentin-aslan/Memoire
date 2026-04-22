// tokens.jsx — Mémoire design tokens
// Dark luxury palette, New York (serif) + SF Pro, gold accent #D4AF37.

const MEMOIRE_TOKENS = {
  // Surfaces
  bgPrimary:   '#1C1C1E',
  bgCard:      '#2C2C2E',
  bgElevated: '#3A3A3C',
  bgHairline: 'rgba(84,84,88,0.45)',

  // Text
  textPrimary: '#F5F5F7',
  textReading: '#F2EDE4',        // warm white for card content
  textSecondary: 'rgba(235,235,245,0.60)',
  textTertiary:  'rgba(235,235,245,0.30)',

  // Accents (Gold) — dédoublé selon la doctrine Liquid Glass
  // gold.solid : sur surfaces opaques (texte, icônes, hairlines, CTAs solides)
  // gold.onGlass : pré-éclairci pour survivre à la vibrancy du verre (UNIQUE USAGE : .glassProminent CTA paywall)
  // gold.muted : états pressés
  gold:         '#D4AF37',   // solid
  goldOnGlass:  '#E6C558',   // onGlass (plus clair, survit à la désaturation du glass)
  goldLight:    '#E5C564',
  goldDark:     '#B8942E',
  goldMuted:    '#A8892B',
  goldTint:     'rgba(212,175,55,0.14)',
  goldTintSoft: 'rgba(212,175,55,0.08)',

  // States
  // "again" = soft warm peach (ex. #FF6B6B trop rouge — adouci vers un corail-pêche)
  again: '#F7A58C',
  good:  '#D4AF37',
  easy:  '#4ADE80',
  againTint: 'rgba(247,165,140,0.10)',
  easyTint:  'rgba(74,222,128,0.12)',

  // Fonts
  serif: `"New York","NewYork","Iowan Old Style","Source Serif Pro",Georgia,serif`,
  sans:  `-apple-system,"SF Pro Text","SF Pro",system-ui,Inter,sans-serif`,
  mono:  `"SF Mono","JetBrains Mono",ui-monospace,monospace`,
};

window.MEMOIRE_TOKENS = MEMOIRE_TOKENS;
window.T = MEMOIRE_TOKENS;
