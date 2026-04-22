// screens-review.jsx — Review session (flip card + 3-button rating) + Complete

const T = window.T;

// ─────────────────────────────────────────────────────────────
// Review session — the core experience
// ─────────────────────────────────────────────────────────────
function ReviewScreen({ onRate, onFlip, onClose, current = 12, total = 30, card, flipped, lastRating }) {
  const progress = current / total;
  const c = card || {
    front: "Quelle est l'intuition centrale du FSRS ?",
    back: "Modéliser la probabilité de rappel via difficulté, stabilité, récupérabilité — et planifier pour maintenir R = 0.90.",
  };

  return (
    <ScreenShell>
      {/* Top bar: progress + close — Liquid Glass */}
      {(() => {
        const Glass = window.GlassSurface;
        const bar = (
          <div style={{
            display: 'flex', alignItems: 'center', gap: 14,
            padding: '10px 12px',
          }}>
            <button onClick={onClose} style={{
              width: 32, height: 32, borderRadius: 16, border: 'none',
              background: 'rgba(255,255,255,0.12)', color: T.textPrimary,
              fontSize: 14, cursor: 'pointer', flexShrink: 0,
              display: 'grid', placeItems: 'center',
            }}>
              <svg width="12" height="12" viewBox="0 0 12 12"><path d="M2 2l8 8M10 2l-8 8" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/></svg>
            </button>
            <div style={{ flex: 1, height: 3, background: 'rgba(255,255,255,0.12)', borderRadius: 2, overflow: 'hidden' }}>
              <div style={{
                height: '100%', width: `${progress*100}%`,
                background: `linear-gradient(90deg, ${T.goldDark}, ${T.gold}, ${T.goldLight})`,
                borderRadius: 2, boxShadow: `0 0 8px ${T.gold}66`,
                transition: 'width 400ms cubic-bezier(.2,.8,.2,1)',
              }}/>
            </div>
            <div style={{ fontFamily: T.sans, fontSize: 13, color: T.textPrimary, fontVariantNumeric: 'tabular-nums', letterSpacing: 0.2, paddingRight: 4 }}>
              {current}<span style={{ opacity: 0.5 }}>/{total}</span>
            </div>
          </div>
        );
        return (
          <div style={{
            position: 'absolute', top: 52, left: 14, right: 14, zIndex: 20,
          }}>
            {Glass ? (
              <Glass variant="regular" radius={20}>{bar}</Glass>
            ) : (
              <div style={{
                background: 'rgba(28,28,32,0.82)', borderRadius: 20,
                backdropFilter: 'blur(28px) saturate(170%)',
                WebkitBackdropFilter: 'blur(28px) saturate(170%)',
                border: '0.5px solid rgba(255,255,255,0.08)',
              }}>{bar}</div>
            )}
          </div>
        );
      })()}

      {/* Flip card */}
      <div style={{
        position: 'absolute', top: 110, left: 20, right: 20, bottom: 200,
        display: 'grid', placeItems: 'center', perspective: 1400,
      }}>
        <div onClick={onFlip} style={{
          width: '100%', height: '100%', cursor: 'pointer',
          transition: 'transform 600ms cubic-bezier(.2,.8,.2,1)',
          transform: flipped ? 'rotateY(180deg)' : 'rotateY(0deg)',
          transformStyle: 'preserve-3d', position: 'relative',
        }}>
          <CardFace front>{c.front}</CardFace>
          <CardFace>{c.back}</CardFace>
        </div>
      </div>

      {/* Bottom controls: tap-to-reveal hint OR rating buttons */}
      <div style={{
        position: 'absolute', left: 16, right: 16, bottom: 36,
      }}>
        {!flipped ? (
          <div style={{
            textAlign: 'center', height: 52,
            display: 'grid', placeItems: 'center',
            fontFamily: T.sans, fontSize: 14, color: T.textSecondary, letterSpacing: 0.3,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, opacity: 0.8 }}>
              <span style={{
                width: 6, height: 6, borderRadius: 3, background: T.gold,
                boxShadow: `0 0 10px ${T.gold}`,
                animation: 'pulse 1.6s ease-in-out infinite',
              }}/>
              Appuyez pour révéler
            </div>
          </div>
        ) : (
          <div style={{ display: 'flex', gap: 10 }}>
            <RateBtn tone="again" label="Raté" glyph="✕" hint="~1 min" onClick={() => onRate?.('again')} />
            <RateBtn tone="good"  label="Moyen" glyph="○" hint="~4 j" onClick={() => onRate?.('good')} primary />
            <RateBtn tone="easy"  label="Facile" glyph="✓" hint="~12 j" onClick={() => onRate?.('easy')} />
          </div>
        )}
      </div>

      <style>{`
        @keyframes pulse {
          0%, 100% { opacity: 1; transform: scale(1); }
          50% { opacity: 0.3; transform: scale(0.7); }
        }
      `}</style>
    </ScreenShell>
  );
}

function CardFace({ front, children }) {
  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: front
        ? `linear-gradient(180deg, #323234 0%, #262628 100%)`
        : `linear-gradient(180deg, #2C2C2E 0%, #232325 100%)`,
      borderRadius: 26,
      border: '0.5px solid rgba(255,255,255,0.06)',
      boxShadow: '0 30px 60px rgba(0,0,0,0.45), 0 0 0 0.5px rgba(212,175,55,0.08) inset',
      padding: '36px 28px',
      display: 'flex', flexDirection: 'column',
      backfaceVisibility: 'hidden', WebkitBackfaceVisibility: 'hidden',
      transform: front ? 'rotateY(0deg)' : 'rotateY(180deg)',
    }}>
      {/* Tiny label */}
      <div style={{
        fontFamily: T.sans, fontSize: 10, fontWeight: 600,
        color: T.gold, letterSpacing: 2.4, textTransform: 'uppercase',
        opacity: 0.8,
      }}>{front ? 'Question' : 'Réponse'}</div>

      {/* Divider */}
      <div style={{ height: 0.5, background: 'rgba(212,175,55,0.2)', margin: '12px 0 24px' }}/>

      {/* Content */}
      <div style={{
        flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
        textAlign: 'center',
        fontFamily: T.serif,
        fontSize: front ? 26 : 22,
        fontWeight: front ? 500 : 400,
        lineHeight: front ? 1.3 : 1.55,
        color: T.textReading,
        letterSpacing: front ? -0.3 : -0.1,
        textWrap: 'pretty',
      }}>{children}</div>

      {/* Footer meta */}
      <div style={{
        fontFamily: T.sans, fontSize: 11, color: T.textTertiary,
        letterSpacing: 0.8, textAlign: 'center', marginTop: 16,
      }}>FSRS · {front ? 'stabilité 4,2 j' : 'prochaine révision calculée'}</div>
    </div>
  );
}

function RateBtn({ tone, label, glyph, hint, onClick, primary }) {
  const toneMap = {
    again: { color: T.again, bg: 'rgba(247,165,140,0.09)', border: 'rgba(247,165,140,0.26)' },
    good:  { color: T.gold,  bg: 'rgba(212,175,55,0.12)',  border: 'rgba(212,175,55,0.30)' },
    easy:  { color: T.easy,  bg: 'rgba(74,222,128,0.10)',  border: 'rgba(74,222,128,0.28)' },
  }[tone];
  return (
    <button onClick={onClick} style={{
      flex: 1, height: 72, borderRadius: 16,
      background: primary ? `linear-gradient(180deg, rgba(212,175,55,0.22), rgba(212,175,55,0.08))` : toneMap.bg,
      border: `1px solid ${toneMap.border}`,
      color: toneMap.color,
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      gap: 4, cursor: 'pointer',
      fontFamily: T.sans,
      boxShadow: primary ? `0 8px 22px rgba(212,175,55,0.18)` : 'none',
      transition: 'transform 120ms ease',
    }}
      onMouseDown={(e) => e.currentTarget.style.transform = 'scale(0.97)'}
      onMouseUp={(e) => e.currentTarget.style.transform = 'scale(1)'}
      onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <span style={{ fontSize: 13, opacity: 0.9 }}>{glyph}</span>
        <span style={{ fontSize: 15, fontWeight: 650, letterSpacing: 0.1 }}>{label}</span>
      </div>
      <div style={{ fontSize: 11, opacity: 0.7, letterSpacing: 0.3 }}>{hint}</div>
    </button>
  );
}

// ─────────────────────────────────────────────────────────────
// Complete screen
// ─────────────────────────────────────────────────────────────
function CompleteScreen({ onDone }) {
  return (
    <ScreenShell>
      <div style={{
        width: '100%', height: '100%',
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        padding: '0 36px', textAlign: 'center',
      }}>
        {/* Gold check */}
        <div style={{
          width: 104, height: 104, borderRadius: 52,
          background: `radial-gradient(circle, rgba(212,175,55,0.28) 0%, rgba(212,175,55,0) 70%)`,
          display: 'grid', placeItems: 'center',
          animation: 'pulse-glow 3s ease-in-out infinite',
          marginBottom: 8,
        }}>
          <div style={{
            width: 64, height: 64, borderRadius: 32,
            background: `linear-gradient(135deg, ${T.goldLight}, ${T.gold}, ${T.goldDark})`,
            display: 'grid', placeItems: 'center',
            boxShadow: `0 0 40px ${T.gold}88, 0 10px 30px rgba(0,0,0,0.4)`,
          }}>
            <svg width="28" height="28" viewBox="0 0 28 28" fill="none">
              <path d="M6 14l5 5 11-12" stroke="#1A1405" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        </div>

        <div style={{
          fontFamily: T.serif, fontSize: 30, fontWeight: 500,
          color: T.textReading, marginTop: 32, letterSpacing: -0.3, lineHeight: 1.2,
        }}>Parfait.</div>
        <div style={{
          fontFamily: T.serif, fontSize: 22, fontWeight: 400,
          color: T.textSecondary, marginTop: 8, letterSpacing: -0.2,
        }}>Révision terminée.</div>

        {/* Stats */}
        <div style={{
          marginTop: 48, display: 'flex', gap: 36,
          fontFamily: T.sans,
        }}>
          <Stat value="30" label="cartes"/>
          <div style={{ width: 0.5, background: T.bgHairline }}/>
          <Stat value="6:24" label="durée"/>
          <div style={{ width: 0.5, background: T.bgHairline }}/>
          <Stat value="92%" label="précision" gold/>
        </div>

        <div style={{
          marginTop: 56,
          fontFamily: T.sans, fontSize: 13, color: T.textSecondary,
          letterSpacing: 0.4, maxWidth: 260, lineHeight: 1.5,
        }}>Prochaine session suggérée demain vers 18h.</div>

        <div style={{ width: '100%', marginTop: 32 }}>
          <GoldButton onClick={onDone}>Retour à l'accueil</GoldButton>
        </div>
      </div>

      <style>{`
        @keyframes pulse-glow {
          0%, 100% { transform: scale(1); opacity: 1; }
          50% { transform: scale(1.08); opacity: 0.85; }
        }
      `}</style>
    </ScreenShell>
  );
}

function Stat({ value, label, gold }) {
  return (
    <div>
      <div style={{
        fontFamily: T.serif, fontSize: 28, fontWeight: 500,
        color: gold ? T.gold : T.textReading, letterSpacing: -0.5, lineHeight: 1,
      }}>{value}</div>
      <div style={{
        fontFamily: T.sans, fontSize: 11, color: T.textSecondary,
        marginTop: 6, letterSpacing: 1.4, textTransform: 'uppercase',
      }}>{label}</div>
    </div>
  );
}

Object.assign(window, { ReviewScreen, CompleteScreen });
