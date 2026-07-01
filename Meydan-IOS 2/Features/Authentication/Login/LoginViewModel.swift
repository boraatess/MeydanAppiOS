import Foundation
import AuthenticationServices
@preconcurrency import GoogleSignIn

@MainActor
class LoginViewModel: ObservableObject {
    
    @Published var credential = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let authManager: AuthenticationManager
    private let service: AuthServiceProtocol
    
    init(service: AuthServiceProtocol, authManager: AuthenticationManager) {
        self.service = service
        self.authManager = authManager
    }
    
    func login() async {
        guard !credential.isEmpty, !password.isEmpty else {
            errorMessage = "Lütfen tüm alanları doldurun."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await service.login(credential: credential, password: password)
            print("Giriş başarılı! Token: \(response.token)")
            authManager.login(token: response.token)
        } catch {
            // TODO: API'dan gelen özel hatayı parse edip kullanıcıya göster.
            self.errorMessage = "Giriş bilgileri hatalı veya bir sorun oluştu."
        }
        
        self.isLoading = false
    }
    
    func handleSocialSignIn() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Google Girişi
            let googleResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: await UIApplication.shared.topViewController()!)
            guard let googleIdToken = googleResult.user.idToken?.tokenString else { throw URLError(.badServerResponse) }
            guard let googleProviderId = googleResult.user.userID else { throw URLError(.badServerResponse) }

            let response = try await service.signInWithSocial(
                provider: "google",
                providerId: googleProviderId,
                token: googleIdToken,
                fullName: googleResult.user.profile?.name,
                email: googleResult.user.profile?.email
            )
            
            print("Google ile giriş/kayıt başarılı! Token: \(response.token)")
            // TODO: Token'ı Keychain'e kaydet ve ana ekrana yönlendir.
            
        } catch {
            self.errorMessage = "Google ile giriş başarısız: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        
        do {
            switch result {
            case .success(let auth):
                guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                      let appleIdTokenData = appleIDCredential.identityToken,
                      let appleIdToken = String(data: appleIdTokenData, encoding: .utf8)
                else {
                    throw URLError(.badServerResponse)
                }
                
                let fullName = (appleIDCredential.fullName?.givenName ?? "") + " " + (appleIDCredential.fullName?.familyName ?? "")
                
                let response = try await service.signInWithSocial(
                    provider: "apple",
                    providerId: appleIDCredential.user,
                    token: appleIdToken,
                    fullName: fullName.trimmingCharacters(in: .whitespaces),
                    email: appleIDCredential.email
                )
                
                print("Apple ile giriş/kayıt başarılı! Token: \(response.token)")
                // TODO: Token'ı Keychain'e kaydet ve ana ekrana yönlendir.
                
            case .failure(let error):
                throw error
            }
        } catch {
            self.errorMessage = "Apple ile giriş başarısız: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
