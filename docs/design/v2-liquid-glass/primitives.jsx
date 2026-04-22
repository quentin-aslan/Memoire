// primitives.jsx — Mémoire shared UI primitives
// Assumes window.T (tokens) is available.

const T = window.T;

// ─────────────────────────────────────────────────────────────
// Ring (Apple Fitness-style progress ring, gold)
// ─────────────────────────────────────────────────────────────
function Ring({ size = 180, stroke = 14, progress = 0.7, color = T.gold, track = 'rgba(255,255,255,0.06)', children, glow = true }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const off = c * (1 - progress);
  return (
    <div style={{ position: 'relative', width: size, height: size, display: 'grid', placeItems: 'center' }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)', position: 'absolute', inset: 0, filter: glow ? `drop-shadow(0 0 14px ${T.gold}55)` : 'none' }}>
        <circle cx={size/2} cy={size/2} r={r} stroke={track} strokeWidth={stroke} fill="none"/>
        <circle cx={size/2} cy={size/2} r={r} stroke={color} strokeWidth={stroke} strokeLinecap="round" fill="none"
          strokeDasharray={c} strokeDashoffset={off}
          style={{ transition: 'stroke-dashoffset 600ms cubic-bezier(.2,.8,.2,1)' }}/>
      </svg>
      <div style={{ position: 'relative', zIndex: 1, textAlign: 'center' }}>{children}</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Regularity micro-ring
// ─────────────────────────────────────────────────────────────
function MicroRing({ value = 14, max = 30, size = 28, stroke = 3 }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const off = c * (1 - value/max);
  return (
    <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
      <circle cx={size/2} cy={size/2} r={r} stroke="rgba(212,175,55,0.2)" strokeWidth={stroke} fill="none"/>
      <circle cx={size/2} cy={size/2} r={r} stroke={T.gold} strokeWidth={stroke} strokeLinecap="round" fill="none"
        strokeDasharray={c} strokeDashoffset={off}/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// Primary gold button (52pt)
// ─────────────────────────────────────────────────────────────
function GoldButton({ children, onClick, disabled, style = {}, full = true, subtitle }) {
  return (
    <button onClick={onClick} disabled={disabled} style={{
      width: full ? '100%' : 'auto',
      height: 52,
      padding: '0 22px',
      border: 'none',
      borderRadius: 14,
      background: disabled ? T.goldDark : `linear-gradient(180deg, ${T.goldLight} 0%, ${T.gold} 55%, ${T.goldDark} 100%)`,
      color: '#1A1405',
      fontFamily: T.sans,
      fontSize: 17,
      fontWeight: 650,
      letterSpacing: 0.1,
      cursor: disabled ? 'default' : 'pointer',
      boxShadow: '0 1px 0 rgba(255,255,255,0.18) inset, 0 -1px 0 rgba(0,0,0,0.2) inset, 0 10px 24px rgba(212,175,55,0.22)',
      transition: 'transform 120ms ease, box-shadow 120ms ease',
      ...style,
    }}
    onMouseDown={(e) => e.currentTarget.style.transform = 'scale(0.985)'}
    onMouseUp={(e) => e.currentTarget.style.transform = 'scale(1)'}
    onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
    >{children}</button>
  );
}

function GhostButton({ children, onClick, style = {} }) {
  return (
    <button onClick={onClick} style={{
      width: '100%',
      height: 44,
      border: `1px solid ${T.bgHairline}`,
      borderRadius: 12,
      background: 'transparent',
      color: T.textPrimary,
      fontFamily: T.sans,
      fontSize: 15,
      fontWeight: 500,
      cursor: 'pointer',
      ...style,
    }}>{children}</button>
  );
}

// ─────────────────────────────────────────────────────────────
// Status chip
// ─────────────────────────────────────────────────────────────
function Chip({ children, color = T.gold, bg = T.goldTint, style = {} }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      height: 22, padding: '0 9px', borderRadius: 999,
      background: bg, color,
      fontFamily: T.sans, fontSize: 11.5, fontWeight: 600,
      letterSpacing: 0.2, textTransform: 'uppercase',
      ...style,
    }}>{children}</span>
  );
}

// ─────────────────────────────────────────────────────────────
// Tab bar (4 tabs)
// ─────────────────────────────────────────────────────────────
const TABS = [
  { id: 'home',     label: 'Accueil',  icon: HomeIcon },
  { id: 'review',   label: 'Réviser',  icon: ReviewIcon },
  { id: 'decks',    label: 'Paquets',  icon: DecksIcon },
  { id: 'settings', label: 'Réglages', icon: SettingsIcon },
];

function TabBar({ active = 'home', onChange }) {
  const glassMode = (window.useGlass && window.useGlass()) || 'on';
  const Glass = window.GlassSurface;

  const content = (
    <div style={{
      height: 54, paddingTop: 4,
      display: 'flex', justifyContent: 'space-around', alignItems: 'center',
    }}>
      {TABS.map(tab => {
        const Icon = tab.icon;
        const on = active === tab.id;
        return (
          <button key={tab.id} onClick={() => onChange?.(tab.id)} style={{
            flex: 1, background: 'none', border: 'none',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            padding: '4px 0', cursor: 'pointer',
            color: on ? T.gold : '#8E8E93',
            fontFamily: T.sans, fontSize: 10, fontWeight: 500,
            letterSpacing: 0.15, position: 'relative', zIndex: 1,
          }}>
            {on && (
              <span aria-hidden="true" style={{
                position: 'absolute', bottom: 2, left: '50%', transform: 'translateX(-50%)',
                width: 14, height: 2, borderRadius: 1,
                background: T.gold,
                boxShadow: `0 0 6px ${T.gold}aa`,
              }}/>
            )}
            <span style={{ position: 'relative', zIndex: 1 }}><Icon active={on} /></span>
            <span style={{ position: 'relative', zIndex: 1, fontWeight: on ? 600 : 500 }}>{tab.label}</span>
          </button>
        );
      })}
    </div>
  );

  return (
    <div style={{
      position: 'absolute', left: 10, right: 10, bottom: 18,
      zIndex: 30,
    }}>
      {Glass ? (
        <Glass variant="regular" radius={22} style={{ padding: 0 }}>
          {content}
        </Glass>
      ) : (
        // Fallback if glass.jsx hasn't loaded
        <div style={{
          background: 'rgba(28,28,32,0.82)', borderRadius: 22,
          backdropFilter: 'blur(28px) saturate(170%)',
          WebkitBackdropFilter: 'blur(28px) saturate(170%)',
          border: '0.5px solid rgba(255,255,255,0.08)',
        }}>
          {content}
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Icons — custom, line style
// ─────────────────────────────────────────────────────────────
function HomeIcon({ active }) {
  const c = active ? T.gold : '#8E8E93';
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
      <path d="M4 11l8-6.5L20 11v8.5a1.5 1.5 0 01-1.5 1.5H14v-6h-4v6H5.5A1.5 1.5 0 014 19.5V11z"
        stroke={c} strokeWidth="1.6" fill={active ? 'rgba(212,175,55,0.15)' : 'none'} strokeLinejoin="round"/>
    </svg>
  );
}
function ReviewIcon({ active }) {
  const c = active ? T.gold : '#8E8E93';
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
      <rect x="4" y="6" width="14" height="12" rx="2.2" stroke={c} strokeWidth="1.6"/>
      <rect x="7" y="3" width="14" height="12" rx="2.2" stroke={c} strokeWidth="1.6" fill={active ? 'rgba(212,175,55,0.15)' : 'none'}/>
    </svg>
  );
}
function DecksIcon({ active }) {
  const c = active ? T.gold : '#8E8E93';
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
      <rect x="3" y="5" width="8.5" height="14" rx="2" stroke={c} strokeWidth="1.6" fill={active ? 'rgba(212,175,55,0.15)' : 'none'}/>
      <rect x="12.5" y="5" width="8.5" height="14" rx="2" stroke={c} strokeWidth="1.6"/>
    </svg>
  );
}
function SettingsIcon({ active }) {
  const c = active ? T.gold : '#8E8E93';
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="3" stroke={c} strokeWidth="1.6" fill={active ? 'rgba(212,175,55,0.15)' : 'none'}/>
      <path d="M12 2v3M12 19v3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M2 12h3M19 12h3M4.9 19.1L7 17M17 7l2.1-2.1"
        stroke={c} strokeWidth="1.6" strokeLinecap="round"/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// Screen shell — dark canvas with status bar
// ─────────────────────────────────────────────────────────────
function ScreenShell({ children, time = '18:04', scrollable = true, noBar = false, style = {} }) {
  return (
    <div style={{
      width: '100%', height: '100%',
      background: T.bgPrimary, color: T.textPrimary,
      fontFamily: T.sans, position: 'relative', overflow: 'hidden',
      ...style,
    }}>
      {!noBar && (
        <div style={{ position: 'absolute', top: 0, left: 0, right: 0, zIndex: 40 }}>
          <IOSStatusBar dark={true} time={time}/>
        </div>
      )}
      <div style={{ width: '100%', height: '100%', overflow: scrollable ? 'auto' : 'hidden' }}>
        {children}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Subtle shimmer text (for completion states)
// ─────────────────────────────────────────────────────────────
function goldGradient() {
  return `linear-gradient(135deg, ${T.goldLight} 0%, ${T.gold} 50%, ${T.goldDark} 100%)`;
}

Object.assign(window, {
  Ring, MicroRing, GoldButton, GhostButton, Chip, TabBar,
  ScreenShell, goldGradient,
  HomeIcon, ReviewIcon, DecksIcon, SettingsIcon,
});
