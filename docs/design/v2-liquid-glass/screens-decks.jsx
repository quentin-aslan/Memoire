// screens-decks.jsx — Decks list + Card detail + Create card

const T = window.T;

const SAMPLE_DECKS = [
  { id: 'd1', name: 'Swift & SwiftUI',    cards: 142, due: 18, color: '#D4AF37' },
  { id: 'd2', name: 'Neurosciences TDAH', cards: 86,  due: 7,  color: '#B5A9F3' },
  { id: 'd3', name: 'Kanji N3',           cards: 210, due: 5,  color: '#F2B8A6' },
  { id: 'd4', name: 'Stoïcisme — lectures', cards: 48, due: 0, color: '#9AD3B6' },
  { id: 'd5', name: 'UI patterns iOS',    cards: 64,  due: 0,  color: '#7FB8D4' },
];

function DecksScreen({ onOpenDeck, onOpenCard }) {
  return (
    <ScreenShell>
      <div style={{ padding: '62px 24px 16px' }}>
        <div style={{
          display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between',
        }}>
          <div>
            <div style={{
              fontFamily: T.sans, fontSize: 12, fontWeight: 500,
              color: T.textSecondary, letterSpacing: 1.6, textTransform: 'uppercase',
            }}>Bibliothèque</div>
            <div style={{
              fontFamily: T.serif, fontSize: 34, fontWeight: 500,
              color: T.textPrimary, marginTop: 4, letterSpacing: -0.5,
            }}>Paquets</div>
          </div>
          <button style={{
            width: 40, height: 40, borderRadius: 20, border: 'none',
            background: T.goldTint, color: T.gold, fontSize: 22, fontWeight: 300,
            cursor: 'pointer', display: 'grid', placeItems: 'center',
          }}>
            <svg width="16" height="16" viewBox="0 0 16 16"><path d="M8 2v12M2 8h12" stroke={T.gold} strokeWidth="1.8" strokeLinecap="round"/></svg>
          </button>
        </div>
      </div>

      <div style={{ padding: '8px 16px 140px' }}>
        {SAMPLE_DECKS.map((d, i) => (
          <DeckRow key={d.id} deck={d} onClick={() => onOpenDeck?.(d)} first={i === 0}/>
        ))}

        {/* Summary */}
        <div style={{
          marginTop: 24, padding: '14px 18px', borderRadius: 14,
          background: 'rgba(255,255,255,0.02)',
          border: `0.5px dashed ${T.bgHairline}`,
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          fontFamily: T.sans, fontSize: 13, color: T.textSecondary,
        }}>
          <span>5 paquets · 550 cartes</span>
          <span style={{ color: T.gold }}>30 dues</span>
        </div>
      </div>
    </ScreenShell>
  );
}

function DeckRow({ deck, onClick, first }) {
  return (
    <button onClick={onClick} style={{
      width: '100%', margin: '6px 0',
      padding: '16px 18px',
      background: T.bgCard,
      border: '0.5px solid rgba(255,255,255,0.04)',
      borderRadius: 18,
      display: 'flex', alignItems: 'center', gap: 14,
      cursor: 'pointer', textAlign: 'left',
      fontFamily: T.sans,
    }}>
      {/* Color spine */}
      <div style={{
        width: 4, height: 40, borderRadius: 2,
        background: deck.color,
        boxShadow: `0 0 10px ${deck.color}66`,
      }}/>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 16, fontWeight: 600, color: T.textPrimary,
          letterSpacing: -0.1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{deck.name}</div>
        <div style={{
          fontSize: 12, color: T.textSecondary, marginTop: 3,
          letterSpacing: 0.2,
        }}>{deck.cards} cartes</div>
      </div>
      {deck.due > 0 ? (
        <div style={{
          padding: '4px 10px', borderRadius: 99,
          background: T.goldTint, color: T.gold,
          fontFamily: T.serif, fontSize: 15, fontWeight: 500,
          letterSpacing: 0.2, fontVariantNumeric: 'tabular-nums',
        }}>{deck.due}</div>
      ) : (
        <div style={{
          fontFamily: T.sans, fontSize: 12, color: T.textTertiary,
          letterSpacing: 0.3,
        }}>à jour</div>
      )}
      <svg width="7" height="12" viewBox="0 0 7 12"><path d="M1 1l5 5-5 5" stroke={T.textTertiary} strokeWidth="1.5" fill="none" strokeLinecap="round"/></svg>
    </button>
  );
}

// ─────────────────────────────────────────────────────────────
// Card detail
// ─────────────────────────────────────────────────────────────
function CardDetailScreen({ onBack }) {
  return (
    <ScreenShell>
      {/* Top bar */}
      <div style={{
        position: 'absolute', top: 56, left: 16, right: 16,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between', zIndex: 20,
      }}>
        <button onClick={onBack} style={{
          border: 'none', background: 'rgba(255,255,255,0.06)', color: T.gold,
          fontFamily: T.sans, fontSize: 14, fontWeight: 500,
          padding: '6px 14px 6px 10px', borderRadius: 99, cursor: 'pointer',
          display: 'flex', alignItems: 'center', gap: 4,
        }}>
          <svg width="8" height="14" viewBox="0 0 8 14"><path d="M7 1L1 7l6 6" stroke="currentColor" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
          Paquet
        </button>
        <button style={{
          border: 'none', background: 'rgba(255,255,255,0.06)', color: T.textSecondary,
          width: 32, height: 32, borderRadius: 16, cursor: 'pointer',
          display: 'grid', placeItems: 'center',
        }}>
          <svg width="14" height="4" viewBox="0 0 14 4"><circle cx="2" cy="2" r="1.5" fill="currentColor"/><circle cx="7" cy="2" r="1.5" fill="currentColor"/><circle cx="12" cy="2" r="1.5" fill="currentColor"/></svg>
        </button>
      </div>

      <div style={{ padding: '108px 20px 140px' }}>
        {/* Label */}
        <div style={{
          fontFamily: T.sans, fontSize: 11, fontWeight: 600,
          color: T.gold, letterSpacing: 2.4, textTransform: 'uppercase', marginBottom: 12,
        }}>Swift & SwiftUI · Carte</div>

        {/* Question */}
        <div style={{
          fontFamily: T.serif, fontSize: 22, fontWeight: 500,
          color: T.textReading, lineHeight: 1.35, letterSpacing: -0.2,
        }}>Quelle est l'intuition centrale du FSRS ?</div>

        {/* Answer */}
        <div style={{
          marginTop: 20, padding: '18px 18px',
          background: T.bgCard, borderRadius: 16,
          border: '0.5px solid rgba(255,255,255,0.04)',
          fontFamily: T.serif, fontSize: 17, fontWeight: 400,
          color: T.textReading, lineHeight: 1.6, letterSpacing: -0.1,
        }}>
          Modéliser la probabilité de rappel via difficulté, stabilité et récupérabilité — puis planifier les révisions pour maintenir R ≈ 0,90.
        </div>

        {/* Next review callout */}
        <div style={{
          marginTop: 28,
          padding: '20px 20px',
          background: `linear-gradient(135deg, rgba(212,175,55,0.10), rgba(212,175,55,0.02))`,
          border: `0.5px solid rgba(212,175,55,0.22)`,
          borderRadius: 18,
        }}>
          <div style={{
            display: 'flex', alignItems: 'baseline', gap: 10,
            fontFamily: T.serif,
          }}>
            <div style={{ fontSize: 32, fontWeight: 500, color: T.gold, letterSpacing: -0.5, lineHeight: 1.1 }}>22 avril</div>
            <div style={{ fontSize: 14, color: T.textSecondary, fontFamily: T.sans }}>dans 4 jours</div>
          </div>
          <div style={{
            marginTop: 14, fontFamily: T.sans, fontSize: 13,
            color: T.textSecondary, lineHeight: 1.55,
          }}>Prochaine révision calculée par FSRS. La carte n'a pas « disparu » — elle reviendra au bon moment.</div>
        </div>

        {/* Timeline */}
        <div style={{ marginTop: 24 }}>
          <SectionLabel>Planning</SectionLabel>
          <Timeline/>
        </div>

        {/* Stats grid */}
        <div style={{
          marginTop: 24,
          display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10,
        }}>
          <StatCard label="État" value="En révision" small/>
          <StatCard label="Difficulté" value="Moyenne" chipColor={T.gold} small/>
          <StatCard label="Révisions" value="14" small/>
          <StatCard label="Dernière" value="Il y a 3j" small/>
        </div>
      </div>
    </ScreenShell>
  );
}

function SectionLabel({ children }) {
  return (
    <div style={{
      fontFamily: T.sans, fontSize: 11, fontWeight: 600,
      color: T.textSecondary, letterSpacing: 1.8, textTransform: 'uppercase',
      marginBottom: 12,
    }}>{children}</div>
  );
}

function StatCard({ label, value, chipColor, small }) {
  return (
    <div style={{
      padding: '14px 16px', background: T.bgCard, borderRadius: 14,
      border: '0.5px solid rgba(255,255,255,0.04)',
    }}>
      <div style={{
        fontFamily: T.sans, fontSize: 11, color: T.textSecondary,
        letterSpacing: 0.8, textTransform: 'uppercase', fontWeight: 500,
      }}>{label}</div>
      <div style={{
        fontFamily: T.serif, fontSize: small ? 18 : 22,
        fontWeight: 500, color: chipColor || T.textReading,
        marginTop: 4, letterSpacing: -0.2,
      }}>{value}</div>
    </div>
  );
}

function Timeline() {
  // Sequence of dots: past (filled), today (gold), future (outlined)
  const dots = [
    { label: '1j',   state: 'past' },
    { label: '3j',   state: 'past' },
    { label: '7j',   state: 'past' },
    { label: 'AUJ',  state: 'now' },
    { label: '+4j',  state: 'future' },
    { label: '+11j', state: 'future' },
    { label: '+27j', state: 'future' },
  ];
  return (
    <div style={{ position: 'relative', padding: '8px 4px' }}>
      {/* Line */}
      <div style={{
        position: 'absolute', top: 18, left: 14, right: 14,
        height: 0.5, background: `linear-gradient(90deg, ${T.gold}55, ${T.bgHairline} 50%, ${T.bgHairline})`,
      }}/>
      <div style={{ display: 'flex', justifyContent: 'space-between', position: 'relative' }}>
        {dots.map((d, i) => (
          <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
            <div style={{
              width: d.state === 'now' ? 14 : 10,
              height: d.state === 'now' ? 14 : 10,
              borderRadius: 99,
              background: d.state === 'past' ? T.gold
                        : d.state === 'now'  ? T.gold
                        : 'transparent',
              border: d.state === 'future' ? `1.5px solid ${T.bgHairline}` : 'none',
              boxShadow: d.state === 'now' ? `0 0 12px ${T.gold}, 0 0 0 3px rgba(212,175,55,0.18)` : 'none',
            }}/>
            <div style={{
              fontFamily: T.sans, fontSize: 10, fontWeight: 600,
              color: d.state === 'now' ? T.gold : T.textTertiary,
              letterSpacing: 0.6,
            }}>{d.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, { DecksScreen, CardDetailScreen, SAMPLE_DECKS });
