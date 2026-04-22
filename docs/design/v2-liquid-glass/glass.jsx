// glass.jsx — Liquid Glass surfaces for Mémoire (iOS 26)
//
// Doctrine (recherche Liquid Glass × Mémoire, avril 2026) :
//   — Chrome-only : navigation layer uniquement (tab bar, toolbar, sheets, CTA paywall).
//   — Jamais sur contenu éditorial (carte, canvas, listes).
//   — Variante .clear BANNIE du code base.
//   — Une seule app-wide surface glass par écran idéalement.
//   — Mode Calme (quiet) : fallback solide opaque, respect de Reduce Transparency.
//   — Typographie SF Pro avec bump de poids (+1 cran) sur glass pour compenser la vibrancy.
//   — Pas de tint or sur tab bar / toolbar. L'or teinte le glass UNIQUEMENT sur le CTA paywall (.prominent).

const T = window.T;

// React context : mode transmis à tous les descendants sans prop drilling
const GlassContext = React.createContext('on');

function GlassProvider({ mode = 'on', children }) {
  return <GlassContext.Provider value={mode}>{children}</GlassContext.Provider>;
}

function useGlass() {
  return React.useContext(GlassContext);
}

// ─────────────────────────────────────────────────────────────
// GlassSurface — primitive unique
//
// variant:
//   - 'regular'   — tab bars, toolbars, chrome standard (tint 52%)
//   - 'prominent' — sheets, menus, CTAs paywall, alerts (tint 68% + halo)
//
// tint: 'dark' (défaut) | 'goldOnGlass' (UNIQUEMENT pour CTA paywall) | color CSS
// ─────────────────────────────────────────────────────────────
function GlassSurface({
  variant = 'regular',
  tint = 'dark',
  radius = 20,
  children,
  style = {},
  onClick,
  as: Tag = 'div',
  ...rest
}) {
  const mode = useGlass();

  // Base tint color (dark-first app → cool graphite base #1C1C1E)
  let baseColor;
  if (tint === 'goldOnGlass') {
    baseColor = [230, 197, 88];         // #E6C558 — survit à la vibrancy
  } else if (tint === 'dark' || !tint) {
    baseColor = [28, 28, 30];           // #1C1C1E
  } else {
    baseColor = null;                   // let consumer override via style.background
  }

  // Alpha par variant — plus opaque que bêta 1 WWDC (cf. iOS 26.1 "Tinted" par défaut)
  const alpha = variant === 'prominent' ? 0.68 : 0.52;

  const glassBg = baseColor
    ? `rgba(${baseColor[0]},${baseColor[1]},${baseColor[2]},${alpha})`
    : undefined;

  // Mode Calme (quiet) → opaque solide, zéro blur, zéro specular
  // Respect de Reduce Transparency (WCAG) et photophobie TDAH
  const quietBg = tint === 'goldOnGlass' ? '#E6C558' : '#2A2A2C'; // surface.raised

  const isQuiet = mode === 'quiet';

  const glassShared = {
    borderRadius: radius,
    background: isQuiet ? quietBg : glassBg,
    // Backdrop: blur plus contenu qu'en bêta 1 (saturate 165, pas 200)
    backdropFilter: isQuiet ? 'none' : 'blur(30px) saturate(165%)',
    WebkitBackdropFilter: isQuiet ? 'none' : 'blur(30px) saturate(165%)',
    // Double bordure adoucie : halo extérieur fin + highlight spéculaire discret
    // (spéculaire atténué vs. v1 pour éviter la plainte "bright flashing" iOS 26.4)
    boxShadow: isQuiet
      ? '0 1px 0 rgba(255,255,255,0.04) inset, 0 8px 24px rgba(0,0,0,0.32)'
      : [
          '0 0 0 0.5px rgba(255,255,255,0.05)',           // hairline edge
          '0 1px 0 rgba(255,255,255,0.10) inset',         // specular top (atténué)
          '0 -1px 0 rgba(0,0,0,0.22) inset',              // bottom shade
          '0 14px 40px rgba(0,0,0,0.45)',                 // lift shadow
          '0 0 0 0.5px rgba(0,0,0,0.35)',                 // outer bleed
        ].join(', '),
    // Très léger gradient d'éclairage inset (pas un mirror reflection — restraint)
    backgroundImage: isQuiet
      ? 'none'
      : 'linear-gradient(180deg, rgba(255,255,255,0.04) 0%, rgba(255,255,255,0) 34%, rgba(255,255,255,0) 68%, rgba(0,0,0,0.10) 100%)',
    position: 'relative',
    overflow: 'hidden',
    ...style,
  };

  return (
    <Tag style={glassShared} onClick={onClick} {...rest}>
      {/* Specular highlight discret — ni "wet", ni shimmer. Un simple arc de 8% d'opacité. */}
      {!isQuiet && (
        <span aria-hidden="true" style={{
          position: 'absolute', inset: 0, pointerEvents: 'none',
          borderRadius: 'inherit',
          background: 'radial-gradient(140% 50% at 50% -15%, rgba(255,255,255,0.08) 0%, rgba(255,255,255,0) 60%)',
        }}/>
      )}
      {children}
    </Tag>
  );
}

// ─────────────────────────────────────────────────────────────
// GlassSheet — bottom sheet / modal (variant prominent)
// ─────────────────────────────────────────────────────────────
function GlassSheet({ children, style = {} }) {
  return (
    <GlassSurface variant="prominent" radius={28} style={{ padding: '20px 20px 28px', ...style }}>
      {/* Grabber */}
      <div style={{
        width: 36, height: 5, borderRadius: 3,
        background: 'rgba(255,255,255,0.22)',
        margin: '0 auto 16px',
      }}/>
      {children}
    </GlassSurface>
  );
}

Object.assign(window, { GlassSurface, GlassSheet, GlassProvider, useGlass });
