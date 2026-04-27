import SwiftUI
import UserNotifications

struct OnboardingFlow: View {
    @Environment(\.appPreferences) private var prefs
    @State private var pageIndex: Int = 0

    private let totalPages = AppConstants.Onboarding.pageCount

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $pageIndex) {
                    WelcomePage().tag(0)
                    NamePage().tag(1)
                    FlipExplainerPage().tag(2)
                    SensitivityPage().tag(3)
                    NotificationPage().tag(4)
                    TwoWordsPage().tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomBar
            }
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            if pageIndex < totalPages - 1 {
                Button("Passer") {
                    finishOnboarding()
                }
                .font(.sans(15, weight: .medium))
                .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .frame(height: 44)
    }

    private var bottomBar: some View {
        VStack(spacing: 20) {
            HStack(spacing: 6) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Capsule()
                        .fill(i == pageIndex ? Color.gold : Color.white.opacity(0.15))
                        .frame(width: i == pageIndex ? 22 : 6, height: 6)
                        .animation(.easeInOut(duration: 0.25), value: pageIndex)
                }
            }

            Button {
                if pageIndex < totalPages - 1 {
                    withAnimation { pageIndex += 1 }
                } else {
                    finishOnboarding()
                }
            } label: {
                Text(ctaLabel)
                    .font(.uiButton)
                    .foregroundStyle(Color.bgPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.goldLight, .gold],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: .rect(cornerRadius: 14)
                    )
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 32)
    }

    // CTA copy follows the page being shown — keep the existing
    // Continuer/Commencer pair for pages 0–3, switch to "J'ai compris" on the
    // new TwoWordsPage so the wording matches the brief §2.1.
    private var ctaLabel: String {
        switch pageIndex {
        case totalPages - 1: return "J'ai compris"
        default:             return "Continuer"
        }
    }

    private func finishOnboarding() {
        prefs.hasOnboarded = true
        Task { await NotificationScheduler.scheduleDaily(hour: prefs.notificationHour) }
    }
}

private struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.goldLight, .gold, .goldDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: Color.gold.opacity(0.35), radius: 30)

                Text("M")
                    .font(.serif(52, weight: .medium))
                    .foregroundStyle(Color.bgPrimary)
            }

            VStack(spacing: 16) {
                Text("Mémoire")
                    .font(.serif(40, weight: .medium))
                    .foregroundStyle(Color.textPrimary)

                Text("Apprenez en profondeur, sans pression.")
                    .font(.serif(19))
                    .italic()
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
            Spacer()
        }
    }
}

private struct NamePage: View {
    @Environment(\.appPreferences) private var prefs
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("Comment tu t'appelles ?")
                .font(.serif(28, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            TextField("Ton prénom", text: Binding(
                get: { prefs.firstName ?? "" },
                set: { prefs.firstName = $0 }
            ))
            .font(.sans(17))
            .foregroundStyle(Color.textPrimary)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .focused($nameFocused)
            .submitLabel(.done)
            .onSubmit { nameFocused = false }
            .padding(18)
            .background(Color.bgCard, in: .rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.goldSubtle, lineWidth: 0.5)
            )
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

private struct FlipExplainerPage: View {
    @State private var flipped = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                flipFace(text: "Qu'est-ce qu'un flip ?")
                    .opacity(flipped ? 0 : 1)

                flipFace(text: "Une carte qui cache sa réponse.")
                    .opacity(flipped ? 1 : 0)
                    .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
            }
            .rotation3DEffect(
                .degrees(flipped ? 180 : 0),
                axis: (0, 1, 0),
                perspective: 0.5
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                    flipped.toggle()
                }
            }

            VStack(spacing: 12) {
                Text("Le flip")
                    .font(.serif(32, weight: .medium))
                    .foregroundStyle(Color.textPrimary)

                Text("Lisez la question, pensez à la réponse, puis appuyez pour vérifier.")
                    .font(.serif(17))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }

    private func flipFace(text: String) -> some View {
        Text(text)
            .font(.serif(22, weight: .regular))
            .foregroundStyle(Color.textReading)
            .multilineTextAlignment(.center)
            .padding(32)
            .frame(width: 260, height: 260)
            .background(Color.surfaceElevated, in: .rect(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.goldSubtle, lineWidth: 0.5)
            )
    }
}

private struct SensitivityPage: View {
    @Environment(\.appPreferences) private var prefs

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "eye")
                .font(.system(size: 42))
                .foregroundStyle(Color.gold)

            VStack(spacing: 14) {
                Text("Sensibilité visuelle")
                    .font(.serif(28, weight: .medium))
                    .foregroundStyle(Color.textPrimary)

                Text("Êtes-vous sensible aux lumières, reflets ou animations (migraine, photophobie) ?")
                    .font(.serif(17))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            VStack(spacing: 10) {
                choiceButton(title: "Oui, activer le Mode Calme", selected: prefs.calmMode) {
                    prefs.calmMode = true
                }
                choiceButton(title: "Non, tout va bien", selected: !prefs.calmMode) {
                    prefs.calmMode = false
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private func choiceButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.sans(15, weight: .medium))
                    .foregroundStyle(selected ? Color.gold : Color.textPrimary)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.gold : Color.textTertiary)
            }
            .padding(18)
            .background(Color.bgCard, in: .rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? Color.goldSubtle : Color.clear, lineWidth: 1)
            )
        }
    }
}

private struct NotificationPage: View {
    @Environment(\.appPreferences) private var prefs
    @State private var permissionStatus: PermissionStatus = .unknown

    enum PermissionStatus {
        case unknown, granted, denied
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "bell.badge")
                .font(.system(size: 42))
                .foregroundStyle(Color.gold)

            VStack(spacing: 14) {
                Text("Un rappel par jour")
                    .font(.serif(28, weight: .medium))
                    .foregroundStyle(Color.textPrimary)

                Text("Une notification à \(prefs.notificationHour)h pour vos révisions.\nAucune pression.")
                    .font(.serif(17))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            hourPicker

            permissionButton

            Spacer()
        }
        .task {
            await refreshPermissionStatus()
        }
    }

    @ViewBuilder
    private var permissionButton: some View {
        switch permissionStatus {
        case .unknown:
            Button {
                Task { await requestNotificationPermission() }
            } label: {
                Text("Autoriser les notifications")
                    .font(.sans(15, weight: .semibold))
                    .foregroundStyle(Color.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.goldSubtle, in: .rect(cornerRadius: 12))
            }
            .padding(.horizontal, 20)

        case .granted:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.stateEasy)
                Text("Notifications autorisées")
                    .font(.sans(14, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.vertical, 14)

        case .denied:
            VStack(spacing: 6) {
                Text("Notifications refusées")
                    .font(.sans(14, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                Text("Activez-les dans Réglages iOS si vous changez d'avis.")
                    .font(.sans(12))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var hourPicker: some View {
        @Bindable var prefs = prefs
        HStack(spacing: 14) {
            Text("Heure")
                .font(.sans(14, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            Picker("", selection: $prefs.notificationHour) {
                ForEach(6..<24, id: \.self) { hour in
                    Text("\(hour)h").tag(hour)
                }
            }
            .labelsHidden()
            .tint(.gold)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.bgCard, in: .rect(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    private func refreshPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: permissionStatus = .granted
        case .denied: permissionStatus = .denied
        case .notDetermined: permissionStatus = .unknown
        @unknown default: permissionStatus = .unknown
        }
    }

    private func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            permissionStatus = granted ? .granted : .denied
        } catch {
            permissionStatus = .denied
        }
    }
}

// Onboarding écran 4 — "Deux mots à connaître". Introduces Solidité + Fraîcheur,
// the two public-facing terms used everywhere else in the app. Only pedagogical
// surface besides the two ⓘ half-sheets, per doctrine A (FSRS stays invisible).

private struct TwoWordsPage: View {
    @State private var appeared: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer().frame(height: 16)

            block(delay: 0) {
                Text("Deux mots à connaître")
                    .font(.serif(32, weight: .semibold))
                    .foregroundStyle(Color.textReading)
                    .lineSpacing(2)
            }

            block(delay: 1) {
                Text("Mémoire mesure deux choses pour chaque carte.")
                    .font(.serif(18))
                    .foregroundStyle(Color.textReading)
                    .lineSpacing(5)
            }

            block(delay: 2) {
                Text("La solidité : à quel point un souvenir tient. Plus tu retrouves une carte, plus elle se solidifie.")
                    .font(.serif(18))
                    .foregroundStyle(Color.textReading)
                    .lineSpacing(5)
            }

            block(delay: 3) {
                Text("La fraîcheur : la probabilité que tu t'en souviennes encore aujourd'hui. Quand elle baisse, Mémoire la ramène.")
                    .font(.serif(18))
                    .foregroundStyle(Color.textReading)
                    .lineSpacing(5)
            }

            block(delay: 4) {
                Text("Tu n'as rien à régler.\nMémoire s'en occupe.")
                    .font(.serif(18))
                    .italic()
                    .foregroundStyle(Color.gold.opacity(0.8))
                    .lineSpacing(3)
                    .padding(.top, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: 0.28)) { appeared = true }
            }
        }
    }

    // Cascade fade-in: each block enters 60ms after the previous one. With
    // reduceMotion the cascade is skipped (everything appears immediately).
    @ViewBuilder
    private func block<C: View>(delay step: Int, @ViewBuilder content: () -> C) -> some View {
        let staggered = Double(step) * 0.06
        content()
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 12)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.28).delay(staggered), value: appeared)
    }
}
