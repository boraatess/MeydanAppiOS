import Foundation
import AuthenticationServices
@preconcurrency import GoogleSignIn
import FirebaseAuth

@MainActor
class LoginViewModel: ObservableObject {
    
    @Published var credential = ""
    @Published var password = ""
    
    // Özel hata mesajları
    @Published var credentialError: String?
    @Published var passwordError: String?
    @Published var generalErrorMessage: String?
    
    // Durum yönetimi
    @Published var isLoading = false
    @Published var isLoggedIn: Bool = false
    
    private let authService: AuthServiceProtocol
    private let authManager: AuthenticationManager
    private var appleSignInCoordinator: AppleSignInCoordinator?
    private let authFlowState: AuthenticationFlowState
    
    init(authService: AuthServiceProtocol, authManager: AuthenticationManager, authFlowState: AuthenticationFlowState) {
        self.authService = authService
        self.authManager = authManager
        self.authFlowState = authFlowState
    }
    
    private func clearErrors() {
        credentialError = nil
        passwordError = nil
        generalErrorMessage = nil
    }
    
    func login() async {
        clearErrors()
        var hasClientError = false
        
        if credential.isEmpty {
            credentialError = "Lütfen kullanıcı adı, e-posta veya telefon girin."
            hasClientError = true
        }
        if password.isEmpty {
            passwordError = "Lütfen parolanızı girin."
            hasClientError = true
        }
        
        if hasClientError { return }
        
        isLoading = true
        
        do {
            let request = LoginRequest(identifier: credential, password: password)
            let response = try await authService.login(request: request)
            
            // Email doğrulama kontrolü
            if let isVerified = response.emailVerified, isVerified == false {
                authFlowState.navigate(to: .activationOTP(email: resolvedEmail()))
                isLoading = false
                return
            }
            
            handleSuccess(response: response)
            
        } catch let error as NetworkError {
            if case .serverError(let message) = error {
                let lowerMessage = message.lowercased()
                
                // Email doğrulanmamış mesajı yakala ve OTP ekranına yönlendir
                if lowerMessage.contains("verify") || lowerMessage.contains("aktivasyon") || lowerMessage.contains("doğrula") {
                    authFlowState.navigate(to: .activationOTP(email: resolvedEmail()))
                } else if lowerMessage.contains("password") || lowerMessage.contains("parola") || lowerMessage.contains("şifre") {
                    passwordError = message
                } else if lowerMessage.contains("user") || lowerMessage.contains("kullanıcı") || lowerMessage.contains("email") {
                    credentialError = message
                } else {
                    generalErrorMessage = message
                }
            } else {
                generalErrorMessage = error.localizedDescription
            }
        } catch {
            generalErrorMessage = "Beklenmedik bir hata oluştu: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Social Login Actions (Tetikleyiciler)
    func signInWithGoogle() async {
        isLoading = true
        clearErrors()
        
        do {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                throw NetworkError.unknown(URLError(.cannotFindHost))
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            // 1. Google Credential oluştur
            let idToken = result.user.idToken?.tokenString ?? ""
            let accessToken = result.user.accessToken.tokenString
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // 2. Firebase ile giriş yap
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // 3. Backend'in beklediği Firebase ID Token'ı al
            let firebaseToken = try await authResult.user.getIDToken()
            
            print("firebase Token : \(firebaseToken)")
            
            
            await sendSocialTokenToBackend(provider: "google", idToken: firebaseToken)
            
        } catch {
            generalErrorMessage = "Google girişi başarısız: \(error.localizedDescription)"
            isLoading = false
        }
    }
        
    func signInWithApple() async {
        isLoading = true
        clearErrors()
        
        appleSignInCoordinator = AppleSignInCoordinator()
        
        do {
            if let appleResult = try await appleSignInCoordinator?.signIn() {
                await sendSocialTokenToBackend(provider: "apple", idToken: appleResult.token)
            } else {
                isLoading = false
            }
        } catch {
            generalErrorMessage = "Apple girişi başarısız: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        clearErrors()
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                generalErrorMessage = "Apple ID Token alınamadı."
                isLoading = false
                return
            }
            await sendSocialTokenToBackend(provider: "apple", idToken: idToken)
        case .failure(let error):
            // Ignore user-cancelled errors silently
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                // no UI error
            } else {
                // Optionally, you can log or set a subtle message, but avoid red error UI
                print("Apple sign-in failed: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    // MARK: - Helpers
    private func sendSocialTokenToBackend(provider: String, idToken: String) async {
        let backendProvider = provider.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = SocialLoginRequest(idToken: idToken, provider: backendProvider )
        print("social login request: \(request)")
        
        do {
            let response = try await authService.socialLogin(request: request)
            
            if let isVerified = response.emailVerified, isVerified == false {
                authFlowState.navigate(to: .activationOTP(email: resolvedEmail()))
                isLoading = false
                return
            }
            
            handleSuccess(response: response)
        } catch let error as NetworkError {
            let lower = error.localizedDescription.lowercased()
            if lower.contains("verify") || lower.contains("aktivasyon") || lower.contains("doğrula") {
                authFlowState.navigate(to: .activationOTP(email: resolvedEmail()))
            } else if lower.contains("token") || lower.contains("firebase") || lower.contains("apple") || lower.contains("google") || lower.contains("401") {
                // Teknik detayı göstermeden genel bir mesaj göster
                generalErrorMessage = "Sosyal giriş başarısız. Lütfen tekrar deneyin."
            } else {
                generalErrorMessage = "Bir şeyler ters gitti. Lütfen tekrar deneyin."
            }
        } catch {
            generalErrorMessage = "Sunucu hatası: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func handleSuccess(response: LoginResponse) {
        guard let token = response.token, !token.isEmpty else {
            generalErrorMessage = response.message ?? "Giriş yanıtında oturum bilgisi bulunamadı."
            isLoggedIn = false
            return
        }

        authManager.login(token: token)
        print("Giriş başarılı: \(response.message ?? "")")
        isLoggedIn = true
    }
    
    private func resolvedEmail() -> String {
        if credential.contains("@") {
            return credential
        } else {
            return ""
        }
    }
}
