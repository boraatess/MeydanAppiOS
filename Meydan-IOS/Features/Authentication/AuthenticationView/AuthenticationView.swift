import SwiftUI

struct AuthenticationView: View {
    @AppStorage("authInitialShowLogin") private var authInitialShowLogin = true
    @State private var showLoginView = true
    @StateObject private var authFlowState: AuthenticationFlowState
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject private var appFlowState: AppFlowState
    
    init(authFlowState: AuthenticationFlowState = AuthenticationFlowState()) {
        _authFlowState = StateObject(wrappedValue: authFlowState)
    }
    
    var body: some View {
        NavigationStack(path: $authFlowState.path) {
            ZStack {
                if showLoginView {
                    LoginView(
                        viewModel: LoginViewModel(authService: AuthService(), authManager: authManager, authFlowState: authFlowState),
                        onShowRegister: {
                        // "Kayıt Ol" butonuna basıldığında Register ekranına geç.
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showLoginView = false
                        }
                    })
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)),
                        removal: .opacity.combined(with: .scale(scale: 1.2))
                    ))
                } else {
                    RegisterView(
                        viewModel: RegisterViewModel(authService: AuthService(), authManager: authManager, authFlowState: authFlowState, appFlowState: appFlowState),
                        onShowLogin: {
                        // "Giriş Yap" butonuna basıldığında Login ekranına geri dön.
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showLoginView = true
                        }
                    })
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)),
                        removal: .opacity.combined(with: .scale(scale: 1.2))
                    ))
                }
            }
            .navigationDestination(for: AuthenticationFlowState.Destination.self) { destination in
                switch destination {
                case .forgotPassword:
                    ForgotPasswordView(viewModel: .init(authFlowState: authFlowState))
                case .verificationCode(let email):
                    // Şifre sıfırlama OTP
                    VerificationCodeView(viewModel: .init(email: email, mode: .resetPassword, authFlowState: authFlowState))
                case .resetPassword(let email, let token):
                    ResetPasswordView(viewModel: .init(email: email, token: token, authFlowState: authFlowState))
                case .activationOTP(let email):
                    // Kayıt aktivasyon OTP
                    VerificationCodeView(viewModel: .init(email: email, mode: .activateAccount, authFlowState: authFlowState))
                case .activationSuccess(let email):
                    // Dinamik başarı ekranı - aktivasyon durumu
                    ActivationSuccessView(mode: .activation(email: email))
                case .birthday(let request):
                    BirthdayView(viewModel: BirthdayViewModel(authService: AuthService(), authManager: authManager, authFlowState: authFlowState, appFlowState: appFlowState, registrationData: request))
                }
            }
        }
        .environmentObject(authFlowState)
        .onAppear {
            showLoginView = authInitialShowLogin
        }
    }
}

@MainActor
class AuthenticationFlowState: ObservableObject {
    @Published var path = NavigationPath()
    
    enum Destination: Hashable {
        case forgotPassword
        case verificationCode(email: String)
        case resetPassword(email: String, token: String)
        case activationOTP(email: String)
        case activationSuccess(email: String)
        case birthday(RegisterRequest)
    }
    
    func navigate(to destination: Destination) {
        path.append(destination)
    }
    
    func navigateBack() {
        path.removeLast()
    }
    
    func navigateToRoot() {
        path.removeLast(path.count)
    }
}
#Preview("Activation OTP") {
    let flow = AuthenticationFlowState()
    flow.navigate(to: .activationOTP(email: "user@example.com"))
    return AuthenticationView(authFlowState: flow)
        .environmentObject(AuthenticationManager())
        .environmentObject(AppFlowState())
        .preferredColorScheme(.dark)
}

#Preview("Reset Password OTP") {
    let flow = AuthenticationFlowState()
    flow.navigate(to: .verificationCode(email: "user@example.com"))
    return AuthenticationView(authFlowState: flow)
        .environmentObject(AuthenticationManager())
        .environmentObject(AppFlowState())
        .preferredColorScheme(.dark)
}

