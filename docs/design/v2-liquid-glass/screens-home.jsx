// screens-home.jsx — Home / Accueil screen
// Dashboard: Cards due ring, regularity score, CTA.

const T = window.T;

function HomeScreen({ onStartReview, state = 'normal' /* normal | empty-decks | empty-due */ }) {
  const cardsDue = state === 'empty-due' ? 0 : 18;
  const totalDue = 30;
  const progress = cardsDue / totalDue;
  const regularity = 21;

  return (
    <ScreenShell>
      {/* Header greeting */}
      <div style={{ padding: '70px 24px 0' }}>
        <div style={{
          fontFamily: T.sans, fontSize: 13, fontWeight: 500,
          color: T.textSecondary, letterSpacing: 1.6, textTransform: 'uppercase',
        }}>Samedi 18 avril</div>
        <div style={{
          fontFamily: T.serif, fontSize: 34, fontWeight: 500,
          color: T.textPrimary, marginTop: 6, letterSpacing: -0.5, lineHeight: 1.1,
        }}>Bonsoir, Quentin.</div>
      </div>

      {/* Main content */}
      {state === 'empty-decks' ? (
        <EmptyDecksState />
      ) : (
        <>
          {/* Main hero — ring for normal, clean centered layout for empty-due */}
          {state === 'empty-due' ? (
            <div style={{ padding: '56px 28px 0', textAlign: 'center' }}>
              <div style={{
                width: 72, height: 72, borderRadius: 36, margin: '0 auto',
                background: `linear-gradient(135deg, ${T.goldLight}, ${T.gold}, ${T.goldDark})`,
                display: 'grid', placeItems: 'center',
                boxShadow: `0 0 40px ${T.gold}66, 0 10px 30px rgba(0,0,0,0.3)`,
              }}>
                <svg width="32" height="32" viewBox="0 0 28 28" fill="none">
                  <path d="M6 14l5 5 11-12" stroke="#1A1405" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
              <div style={{
                fontFamily: T.serif, fontSize: 32, fontWeight: 500,
                color: T.textReading, marginTop: 28, letterSpacing: -0.5, lineHeight: 1.15,
              }}>Journée terminée.</div>
              <div style={{
                fontFamily: T.serif, fontStyle: 'italic', fontSize: 17,
                color: T.textSecondary, marginTop: 10, lineHeight: 1.5, letterSpacing: -0.1,
                maxWidth: 280, margin: '10px auto 0',
              }}>Toutes vos cartes sont à jour. Revenez demain pour poursuivre.</div>
              <div style={{
                display: 'inline-flex', alignItems: 'center', gap: 8,
                marginTop: 24, padding: '6px 14px', borderRadius: 99,
                background: T.goldTint,
                fontFamily: T.sans, fontSize: 12, fontWeight: 600,
                color: T.gold, letterSpacing: 1.2, textTransform: 'uppercase',
              }}>
                <svg width="10" height="10" viewBox="0 0 10 10"><path d="M5 1v8M1 5h8" stroke={T.gold} strokeWidth="1.8" strokeLinecap="round"/></svg>
                1 jour de régularité
              </div>
            </div>
          ) : (
            <div style={{ display: 'grid', placeItems: 'center', marginTop: 38 }}>
              <Ring size={240} stroke={16} progress={1 - progress}>
                <div style={{
                  fontFamily: T.serif, fontSize: 72, fontWeight: 500,
                  color: T.textPrimary, lineHeight: 1, letterSpacing: -2,
                }}>{cardsDue}</div>
                <div style={{
                  fontFamily: T.sans, fontSize: 13, color: T.textSecondary,
                  marginTop: 8, letterSpacing: 1.2, textTransform: 'uppercase',
                }}>Cartes à réviser</div>
              </Ring>
            </div>
          )}

          {/* Regularity */}
          <div style={{
            margin: '38px 20px 0',
            padding: '16px 18px',
            background: T.bgCard,
            borderRadius: 18,
            display: 'flex', alignItems: 'center', gap: 14,
            border: '0.5px solid rgba(255,255,255,0.04)',
          }}>
            <MicroRing value={regularity} max={30} size={36} stroke={4}/>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: T.sans, fontSize: 16, fontWeight: 600, color: T.textPrimary }}>
                Score de régularité
              </div>
              <div style={{ fontFamily: T.sans, fontSize: 13, color: T.textSecondary, marginTop: 2 }}>
                Sur les 30 derniers jours
              </div>
            </div>
            <div style={{
              fontFamily: T.serif, fontSize: 26, color: T.gold, fontWeight: 500,
              letterSpacing: -0.5,
            }}>
              {regularity}<span style={{ color: T.textTertiary, fontSize: 18 }}>/30</span>
            </div>
          </div>

          {/* CTA */}
          <div style={{ padding: '28px 20px 120px' }}>
            {state === 'empty-due' ? (
              <>
                <GoldButton onClick={onStartReview}>Avancer quelques cartes</GoldButton>
                <div style={{
                  textAlign: 'center', marginTop: 12,
                  fontFamily: T.sans, fontSize: 13, color: T.textSecondary,
                }}>Vous pouvez vous arrêter ici.</div>
              </>
            ) : (
              <>
                <GoldButton onClick={onStartReview}>Commencer la révision</GoldButton>
                <div style={{
                  textAlign: 'center', marginTop: 12,
                  fontFamily: T.sans, fontSize: 13, color: T.textSecondary,
                }}>≈ 5 minutes · 3 paquets</div>
              </>
            )}
          </div>
        </>
      )}
    </ScreenShell>
  );
}

function EmptyDecksState() {
  return (
    <div style={{ padding: '48px 28px 120px', textAlign: 'center' }}>
      {/* Gold monogram */}
      <div style={{
        width: 88, height: 88, borderRadius: 24, margin: '8px auto 28px',
        background: `radial-gradient(circle at 30% 30%, ${T.goldLight}, ${T.goldDark})`,
        boxShadow: '0 10px 40px rgba(212,175,55,0.25)',
        display: 'grid', placeItems: 'center',
        fontFamily: T.serif, fontSize: 44, fontWeight: 500, color: '#1A1405',
      }}>M</div>
      <div style={{
        fontFamily: T.serif, fontSize: 24, fontWeight: 500,
        color: T.textReading, lineHeight: 1.25, letterSpacing: -0.2,
      }}>Commencez par un<br/>premier paquet.</div>
      <div style={{
        fontFamily: T.sans, fontSize: 15, color: T.textSecondary,
        marginTop: 12, lineHeight: 1.5, maxWidth: 280, marginLeft: 'auto', marginRight: 'auto',
      }}>Organisez vos cartes par sujet. Ajoutez des questions, laissez l'algorithme faire le reste.</div>

      <div style={{ marginTop: 36 }}>
        <GoldButton>+ Créer un paquet</GoldButton>
        <div style={{ height: 12 }}/>
        <GhostButton>Essayer le paquet de démonstration</GhostButton>
      </div>
    </div>
  );
}

window.HomeScreen = HomeScreen;
