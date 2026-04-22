// screens-settings.jsx — Settings + Onboarding

const T = window.T;

function SettingsScreen() {
  return (
    <ScreenShell>
      <div style={{ padding: '62px 24px 14px' }}>
        <div style={{
          fontFamily: T.sans, fontSize: 12, fontWeight: 500,
          color: T.textSecondary, letterSpacing: 1.6, textTransform: 'uppercase',
        }}>Préférences</div>
        <div style={{
          fontFamily: T.serif, fontSize: 34, fontWeight: 500,
          color: T.textPrimary, marginTop: 4, letterSpacing: -0.5,
        }}>Réglages</div>
      </div>

      <div style={{ padding: '16px 16px 140px' }}>
        <Section title="Session">
          <Row label="Durée de session" value="15 min"/>
          <Row label="Nouvelles cartes / jour" value="10"/>
          <Row label="Rétention désirée" value="0,90" hint="avancé"/>
        </Section>

        <Section title="Rappel">
          <Row label="Heure de notification" value="18:00" chip/>
          <Row label="Son" value="Calme"/>
        </Section>

        <Section title="Apparence">
          <Row label="Thème" value="Sombre"/>
          <Row label="Mouvement réduit" toggle toggled={false}/>
        </Section>

        <Section title="Données">
          <Row label="Exporter (JSON)" value="" chevron/>
          <Row label="Importer" value="" chevron/>
          <Row label="Supprimer toutes les données" danger chevron/>
        </Section>

        <div style={{
          textAlign: 'center', marginTop: 32,
          fontFamily: T.sans, fontSize: 12, color: T.textTertiary, lineHeight: 1.6,
        }}>
          Mémoire v1.0 (build 142)<br/>
          <span style={{ color: T.gold }}>À propos</span> · <span style={{ color: T.gold }}>Confidentialité</span>
        </div>
      </div>
    </ScreenShell>
  );
}

function Section({ title, children }) {
  return (
    <div style={{ marginBottom: 24 }}>
      <div style={{
        fontFamily: T.sans, fontSize: 11, fontWeight: 600,
        color: T.textSecondary, letterSpacing: 1.8, textTransform: 'uppercase',
        padding: '0 8px 10px',
      }}>{title}</div>
      <div style={{
        background: T.bgCard, borderRadius: 18,
        border: '0.5px solid rgba(255,255,255,0.04)', overflow: 'hidden',
      }}>{children}</div>
    </div>
  );
}

function Row({ label, value, hint, chip, toggle, toggled, danger, chevron }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center',
      padding: '14px 16px',
      borderBottom: '0.5px solid rgba(255,255,255,0.04)',
      fontFamily: T.sans,
    }}>
      <div style={{
        flex: 1, fontSize: 15,
        color: danger ? T.again : T.textPrimary,
        letterSpacing: -0.1, fontWeight: 500,
      }}>{label}</div>
      {hint && (
        <span style={{
          marginRight: 8, fontSize: 10, color: T.textTertiary,
          padding: '2px 7px', borderRadius: 99,
          border: `0.5px solid ${T.bgHairline}`, letterSpacing: 0.4,
          textTransform: 'uppercase', fontWeight: 600,
        }}>{hint}</span>
      )}
      {toggle ? (
        <div style={{
          width: 42, height: 24, borderRadius: 12,
          background: toggled ? T.gold : 'rgba(120,120,128,0.3)',
          position: 'relative',
        }}>
          <div style={{
            position: 'absolute', top: 2, left: toggled ? 20 : 2,
            width: 20, height: 20, borderRadius: 10, background: '#fff',
            boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
            transition: 'left 180ms ease',
          }}/>
        </div>
      ) : (
        <>
          {value && (
            <span style={{
              fontSize: 15, color: chip ? T.gold : T.textSecondary,
              fontFamily: chip ? T.serif : T.sans,
              fontWeight: chip ? 500 : 400,
              fontVariantNumeric: 'tabular-nums',
              marginRight: chevron ? 6 : 0,
            }}>{value}</span>
          )}
          {chevron && (
            <svg width="7" height="12" viewBox="0 0 7 12"><path d="M1 1l5 5-5 5" stroke={T.textTertiary} strokeWidth="1.5" fill="none" strokeLinecap="round"/></svg>
          )}
        </>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Onboarding — 4 steps
// ─────────────────────────────────────────────────────────────
function OnboardingScreen({ step = 0, onNext, onSkip }) {
  const steps = [OnboardWelcome, OnboardFlip, OnboardNotif, OnboardFirst];
  const Step = steps[step];
  return (
    <ScreenShell>
      {/* Skip */}
      {step < 3 && (
        <div style={{ position: 'absolute', top: 56, right: 20, zIndex: 20 }}>
          <button onClick={onSkip} style={{
            background: 'none', border: 'none', color: T.textSecondary,
            fontFamily: T.sans, fontSize: 15, cursor: 'pointer', fontWeight: 500,
          }}>Passer</button>
        </div>
      )}
      {/* Dots */}
      <div style={{
        position: 'absolute', top: 66, left: 20, zIndex: 20,
        display: 'flex', gap: 5,
      }}>
        {[0,1,2,3].map(i => (
          <div key={i} style={{
            width: i === step ? 24 : 6, height: 6, borderRadius: 3,
            background: i === step ? T.gold : 'rgba(255,255,255,0.15)',
            transition: 'all 300ms ease',
          }}/>
        ))}
      </div>

      <Step onNext={onNext}/>
    </ScreenShell>
  );
}

function OnboardWelcome({ onNext }) {
  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      justifyContent: 'center', padding: '0 36px 80px', textAlign: 'center',
    }}>
      <div style={{
        width: 92, height: 92, borderRadius: 26, margin: '0 auto 32px',
        background: `linear-gradient(135deg, ${T.goldLight}, ${T.gold}, ${T.goldDark})`,
        boxShadow: `0 20px 50px rgba(212,175,55,0.3), inset 0 1px 0 rgba(255,255,255,0.3)`,
        display: 'grid', placeItems: 'center',
        fontFamily: T.serif, fontSize: 48, fontWeight: 500, color: '#1A1405',
      }}>M</div>
      <div style={{
        fontFamily: T.serif, fontSize: 40, fontWeight: 500,
        color: T.textReading, letterSpacing: -0.8, lineHeight: 1.05,
      }}>Mémoire</div>
      <div style={{
        fontFamily: T.serif, fontStyle: 'italic', fontSize: 17,
        color: T.gold, marginTop: 10, letterSpacing: 0.2,
      }}>Calm luxury for the curious mind.</div>
      <div style={{
        fontFamily: T.sans, fontSize: 15, color: T.textSecondary,
        marginTop: 24, lineHeight: 1.55, maxWidth: 300, margin: '24px auto 0',
      }}>
        Apprendre sans friction, sans culpabilité. L'algorithme s'adapte — vous avancez à votre rythme.
      </div>
      <div style={{ marginTop: 56 }}>
        <GoldButton onClick={onNext}>Commencer</GoldButton>
      </div>
    </div>
  );
}

function OnboardFlip({ onNext }) {
  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      justifyContent: 'center', padding: '0 28px 80px', textAlign: 'center',
    }}>
      {/* Mini demo card */}
      <div style={{ position: 'relative', height: 240, marginBottom: 48, perspective: 1400 }}>
        <div style={{
          position: 'absolute', inset: '0 40px', borderRadius: 20,
          background: `linear-gradient(180deg, #323234, #262628)`,
          border: '0.5px solid rgba(212,175,55,0.15)',
          boxShadow: '0 30px 60px rgba(0,0,0,0.45)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: T.serif, fontSize: 22, fontWeight: 500,
          color: T.textReading, padding: 24,
          animation: 'card-flip 5s ease-in-out infinite',
          transformStyle: 'preserve-3d',
        }}>
          Que veut dire <em style={{ color: T.gold, fontStyle: 'italic' }}>FSRS</em> ?
        </div>
        <style>{`
          @keyframes card-flip {
            0%, 45% { transform: rotateY(0deg); }
            55%, 100% { transform: rotateY(180deg); }
          }
        `}</style>
      </div>

      <div style={{
        fontFamily: T.serif, fontSize: 28, fontWeight: 500,
        color: T.textReading, letterSpacing: -0.3, lineHeight: 1.2,
      }}>Trois boutons.<br/>Aucun jugement.</div>
      <div style={{
        fontFamily: T.sans, fontSize: 15, color: T.textSecondary,
        marginTop: 14, lineHeight: 1.55, maxWidth: 300, margin: '14px auto 0',
      }}>Révélez la réponse. Notez votre rappel — raté, moyen, facile. L'intervalle s'ajuste automatiquement.</div>
      <div style={{ marginTop: 56, padding: '0 24px' }}>
        <GoldButton onClick={onNext}>Continuer</GoldButton>
      </div>
    </div>
  );
}

function OnboardNotif({ onNext }) {
  const hours = ['09:00', '13:00', '18:00', '21:00'];
  const [sel, setSel] = React.useState('18:00');
  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      justifyContent: 'center', padding: '0 28px 80px',
    }}>
      <div style={{
        fontFamily: T.serif, fontSize: 30, fontWeight: 500,
        color: T.textReading, letterSpacing: -0.4, lineHeight: 1.15, textAlign: 'center',
      }}>Quand vous<br/>rappeler ?</div>
      <div style={{
        fontFamily: T.sans, fontSize: 14, color: T.textSecondary,
        marginTop: 14, lineHeight: 1.55, textAlign: 'center', maxWidth: 300, margin: '14px auto 0',
      }}>Un rappel par jour. Modifiable à tout moment.</div>

      <div style={{ marginTop: 36, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        {hours.map(h => (
          <button key={h} onClick={() => setSel(h)} style={{
            padding: '20px 10px', borderRadius: 16,
            background: sel === h ? `linear-gradient(180deg, rgba(212,175,55,0.22), rgba(212,175,55,0.06))` : T.bgCard,
            border: `1px solid ${sel === h ? 'rgba(212,175,55,0.35)' : 'rgba(255,255,255,0.04)'}`,
            color: sel === h ? T.gold : T.textPrimary,
            fontFamily: T.serif, fontSize: 24, fontWeight: 500,
            letterSpacing: -0.3, cursor: 'pointer', fontVariantNumeric: 'tabular-nums',
          }}>
            {h}
            {h === '18:00' && (
              <div style={{
                fontFamily: T.sans, fontSize: 10, fontWeight: 600,
                marginTop: 4, color: sel === h ? T.gold : T.textTertiary,
                letterSpacing: 0.6, textTransform: 'uppercase',
              }}>Recommandé</div>
            )}
          </button>
        ))}
      </div>

      <div style={{ marginTop: 40 }}>
        <GoldButton onClick={onNext}>Activer les rappels</GoldButton>
        <button onClick={onNext} style={{
          width: '100%', marginTop: 10, padding: 14, border: 'none',
          background: 'none', color: T.textSecondary,
          fontFamily: T.sans, fontSize: 14, cursor: 'pointer',
        }}>Pas maintenant</button>
      </div>
    </div>
  );
}

function OnboardFirst({ onNext }) {
  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      justifyContent: 'center', padding: '0 36px 80px', textAlign: 'center',
    }}>
      <div style={{
        fontFamily: T.serif, fontSize: 32, fontWeight: 500,
        color: T.textReading, letterSpacing: -0.4, lineHeight: 1.15,
      }}>Prêt à<br/>commencer.</div>
      <div style={{
        fontFamily: T.sans, fontSize: 15, color: T.textSecondary,
        marginTop: 16, lineHeight: 1.55,
      }}>Un paquet de démonstration de 10 cartes vous attend. Révisez-le en 3 minutes.</div>

      <div style={{
        marginTop: 40, padding: 20, borderRadius: 18,
        background: T.bgCard, border: '0.5px solid rgba(255,255,255,0.06)',
        textAlign: 'left',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ width: 4, height: 36, background: T.gold, borderRadius: 2, boxShadow: `0 0 10px ${T.gold}66` }}/>
          <div>
            <div style={{ fontFamily: T.sans, fontSize: 15, fontWeight: 600, color: T.textPrimary }}>Découvrir la répétition espacée</div>
            <div style={{ fontFamily: T.sans, fontSize: 12, color: T.textSecondary, marginTop: 2 }}>10 cartes · ~3 min</div>
          </div>
        </div>
      </div>

      <div style={{ marginTop: 40 }}>
        <GoldButton onClick={onNext}>Commencer la première révision</GoldButton>
        <button style={{
          width: '100%', marginTop: 10, padding: 14, border: 'none',
          background: 'none', color: T.textSecondary,
          fontFamily: T.sans, fontSize: 14, cursor: 'pointer',
        }}>Créer mon propre paquet</button>
      </div>
    </div>
  );
}

Object.assign(window, { SettingsScreen, OnboardingScreen });
