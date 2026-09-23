import Foundation
import AuthenticationServices
@preconcurrency import GoogleSignIn
import FirebaseAuth

@MainActor
class RegisterViewModel: ObservableObject {
    
    @Published var fullName: String = ""
    @Published var username: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isAgreementAccepted: Bool = false
    
    // Her alan için özel hata mesajları
    @Published var fullNameError: String?
    @Published var usernameError: String?
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    @Published var agreementError: String?
    
    @Published var generalErrorMessage: String?
    
    // State Properties
    @Published var isLoading = false
    @Published var isRegistered = false
    @Published var isLoggedIn = false
    
    // Dependencies
    private var authManager: AuthenticationManager
    private let authService: AuthServiceProtocol
    private var appleSignInCoordinator: AppleSignInCoordinator?
    private let authFlowState: AuthenticationFlowState
    private let appFlowState: AppFlowState
    
    init(authService: AuthServiceProtocol, authManager: AuthenticationManager, authFlowState: AuthenticationFlowState, appFlowState: AppFlowState) {
        self.authService = authService
        self.authManager = authManager
        self.authFlowState = authFlowState
        self.appFlowState = appFlowState
    }
    
    private func validatePassword() -> Bool {
        let passwordRegex = "(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9]).{6,}"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: password)
    }
    
    private func validateEmail() -> Bool {
        CredentialValidation.emailError(email) == nil
    }
    
    private func clearErrors() {
        fullNameError = nil
        usernameError = nil
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        agreementError = nil
        generalErrorMessage = nil
    }
    
    func register() {
        clearErrors()
        var hasClientError = false
        
        if fullName.isEmpty {
            fullNameError = "Ad Soyad boş bırakılamaz."
            hasClientError = true
        }
        
        if username.isEmpty {
            usernameError = "Kullanıcı Adı boş bırakılamaz."
            hasClientError = true
        }
        
        if email.isEmpty {
            emailError = "E-Posta boş bırakılamaz."
            hasClientError = true
        } else if !validateEmail() {
            emailError = "Lütfen geçerli bir e-posta adresi girin."
            hasClientError = true
        }
        
        if let error = CredentialValidation.passwordError(password) {
            passwordError = error
            hasClientError = true
        } else if !validatePassword() {
            passwordError = "Şifreniz, 1 büyük karakter, 1 küçük karakter ve rakam içermelidir."
            hasClientError = true
        }
        
        if confirmPassword.isEmpty {
            confirmPasswordError = "Parola tekrarı boş bırakılamaz."
            hasClientError = true
        } else if password != confirmPassword {
            confirmPasswordError = "Şifreler uyuşmuyor."
            hasClientError = true
        }

        if !isAgreementAccepted {
            agreementError = "Kayıt olmak için kullanıcı sözleşmesini onaylamalısınız."
            hasClientError = true
        }
        
        if let warning = ContentFilter.warning(for: fullName) {
            fullNameError = warning
            hasClientError = true
        }
        if let warning = ContentFilter.warning(for: username) {
            usernameError = warning
            hasClientError = true
        }
        if hasClientError { return }
        
        let request = RegisterRequest(
            fullName: fullName,
            username: username,
            email: email,
            password: password,
            birthday: nil
        )
        
        authFlowState.navigate(to: .birthday(request))
        
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
        generalErrorMessage = nil
        appleSignInCoordinator = AppleSignInCoordinator()
        
        do {
            let appleResult = try await appleSignInCoordinator?.signIn()
            
            guard let token = appleResult?.token else {
                throw NetworkError.serverError(message: "Apple ID Token alınamadı.")
            }
            
            await sendSocialTokenToBackend(provider: "apple", idToken: token)
            
        } catch {
            generalErrorMessage = "Apple girişi başarısız: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        generalErrorMessage = nil
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
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                // Kullanıcı iptal etti, UI'da hata gösterme
            } else {
                print("Apple sign-in failed: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    private func sendSocialTokenToBackend(provider: String, idToken: String) async {
        let backendProvider = provider.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let request = SocialLoginRequest(idToken: idToken, provider: backendProvider )
        do {
            let response = try await authService.socialLogin(request: request)
            if let token = response.token {
                try await FirebaseAuthSessionManager.signInIfNeeded(withCustomToken: response.firebaseToken)
                authManager.login(token: token)
                isLoggedIn = true
                do {
                    let me = try await AuthService().getMe()
                    let user = me.user
                    let isConfirmed = user.confirmed ?? false
                    let hobbies = user.profile?.hobbies ?? []
                    let hasHobbies = !hobbies.isEmpty
                    if !isConfirmed {
                        authFlowState.navigate(to: .activationOTP(email: email))
                    } else if !hasHobbies {
                        appFlowState.navigate(to: .interests)
                    } else {
                        appFlowState.navigate(to: .main)
                    }
                } catch {
                    authFlowState.navigate(to: .activationOTP(email: email))
                }
            } else {
                generalErrorMessage = "Sosyal giriş başarısız. Lütfen tekrar deneyin."
            }
        } catch let error as NetworkError {
            let lower = error.localizedDescription.lowercased()
            if lower.contains("verify") || lower.contains("aktivasyon") || lower.contains("doğrula") {
                authFlowState.navigate(to: .activationOTP(email: email))
            } else if lower.contains("token") || lower.contains("firebase") || lower.contains("apple") || lower.contains("google") || lower.contains("401") {
                generalErrorMessage = "Sosyal giriş başarısız. Lütfen tekrar deneyin."
            } else {
                generalErrorMessage = "Bir şeyler ters gitti. Lütfen tekrar deneyin."
            }
        } catch {
            generalErrorMessage = "Sunucu hatası: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
