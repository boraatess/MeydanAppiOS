import SwiftUI
import Combine
import FirebaseCore
import GoogleMobileAds

@main
struct MeydanApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        guard !RuntimeEnvironment.isSwiftUIPreview else { return }

        FirebaseApp.configure()
        MobileAds.shared.start()
    }
    
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var appFlowState = AppFlowState()
    @State private var isBootstrapping = false
    @State private var isSplashFinished = false
    @State private var verifyPollCancellable: AnyCancellable?
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !isSplashFinished {
                    SplashView(onAnimationComplete: {
                        handlePostSplashRouting()
                    })
                    .environmentObject(authManager)
                    .environmentObject(appFlowState)
                } else {
                    destinationView()
                        .environmentObject(appFlowState)
                }
            }
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                appFlowState.handleDeepLink(url)
            }
            // .dismissKeyboardOnTap() // Test amaçlı geçici olarak kapatıldı
            .onAppear {
                if authManager.isAuthenticated {
                    Task { await runBootstrap() }
                }
            }
            .onChange(of: authManager.isAuthenticated) { isAuth in
                if isAuth {
                    Task { await runBootstrap() }
                } else {
                    TokenStorage.shared.clear()
                    stopVerifyEmailPolling()
                    if isSplashFinished {
                        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
                        appFlowState.navigate(to: hasSeenOnboarding ? .auth : .onboarding)
                    }
                }
            }
    // MARK: - Navigation & Polling Control
    .onChange(of: appFlowState.route) { newRoute in
        if authManager.isAuthenticated, case .verifyEmail = newRoute {
            if verifyPollCancellable == nil {
                startVerifyEmailPolling()
            }
        } else {
            stopVerifyEmailPolling()
        }
    }
}
}

// MARK: - Splash Sonrası Yönlendirme
private func handlePostSplashRouting() {
    if authManager.isAuthenticated {
        isSplashFinished = true
        // İlk açılışta bootstrap'i başlat (State'i etkileyebilir)
        Task { await runBootstrap(isInitial: true) }
    } else {
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        appFlowState.navigate(to: hasSeenOnboarding ? .onboarding : .onboarding)
        isSplashFinished = true
    }
}

// MARK: - Destination View
@ViewBuilder
private func destinationView() -> some View {
    if authManager.isAuthenticated {
        if isBootstrapping {
            Color.black.ignoresSafeArea()
        } else {
            authenticatedView()
        }
    } else {
        unauthenticatedView()
    }
}

@ViewBuilder
private func authenticatedView() -> some View {
    switch appFlowState.route {
    case .main:
        MainTabView()
            .environmentObject(authManager)
    case .interests:
        InterestsView(viewModel: InterestsViewModel(appFlowState: appFlowState))
            .environmentObject(authManager)
    case .birthday:
        BirthdayView(viewModel: BirthdayViewModel(authService: AuthService(), authManager: authManager, authFlowState: AuthenticationFlowState(), appFlowState: appFlowState))
            .environmentObject(authManager)
    case .verifyEmail(let email, let userId):
        NavigationStack {
            VerificationCodeView(
                viewModel: VerificationCodeViewModel(
                    email: email,
                    userId: userId,
                    mode: .activateAccount,
                    authFlowState: AuthenticationFlowState()
                )
            )
        }
        .environmentObject(authManager)
    default:
        AuthenticationView()
            .environmentObject(authManager)
    }
}

@ViewBuilder
private func unauthenticatedView() -> some View {
    switch appFlowState.route {
    case .onboarding:
        OnboardingView()
            .environmentObject(authManager)
    default:
        AuthenticationView()
            .environmentObject(authManager)
    }
}

// MARK: - Bootstrap
@MainActor
private func runBootstrap(isInitial: Bool = false) async {
    // Sadece ilk açılışta isBootstrapping state'ini kullan (ekranın kararması için)
    if isInitial { isBootstrapping = true }
    defer { if isInitial { isBootstrapping = false } }
    
    do {
        let me = try await AuthService().getMe()
        let user = me.user
        // TEMPORARY BYPASS: Email verification skip
        let isConfirmed = true // user.confirmed ?? false
        let hobbies = user.profile?.hobbies ?? []
        
        if !isConfirmed {
            let email = user.email ?? ""
            let userId = user._id ?? user.id ?? ""
            let target = AppFlowState.Route.verifyEmail(email: email, userId: userId)
            if appFlowState.route != target {
                appFlowState.navigate(to: target)
            }
        } else if hobbies.isEmpty {
            if appFlowState.route != .interests {
                appFlowState.navigate(to: .interests)
            }
        } else {
            if appFlowState.route != .main {
                appFlowState.navigate(to: .main)
            }
            await PushNotificationManager.shared.requestPermissionAndRegister()
        }
    } catch let error as NetworkError {
        if case .serverError(let message) = error {
            let normalizedMessage = message.lowercased()
            let isUnauthorized = normalizedMessage.contains("yetkisiz")
                || normalizedMessage.contains("unauthorized")
                || normalizedMessage.contains("invalid token")
                || normalizedMessage.contains("401")

            if isUnauthorized {
                TokenStorage.shared.clear()
                authManager.logout()
                appFlowState.navigate(to: .auth)
            } else if appFlowState.route == .auth {
                appFlowState.navigate(to: .main)
            }
        }
    } catch {
        if appFlowState.route == .auth {
            appFlowState.navigate(to: .main)
        }
    }
}

private func startVerifyEmailPolling() {
    verifyPollCancellable?.cancel()
    // Süreyi 5 saniye olarak güncelliyoruz (Daha makul)
    verifyPollCancellable = Timer.publish(every: 5.0, on: .main, in: .common)
        .autoconnect()
        .sink { _ in Task { await runBootstrap() } }
}
    
    private func stopVerifyEmailPolling() {
        verifyPollCancellable?.cancel()
        verifyPollCancellable = nil
    }
}
