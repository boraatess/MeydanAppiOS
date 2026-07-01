import Foundation
import Alamofire
import AuthenticationServices
@preconcurrency import GoogleSignIn

// PROTOKOL: Auth işlemleri için hangi fonksiyonların olması gerektiğini tanımlar.
@MainActor
protocol AuthServiceProtocol {
    func login(credential: String, password: String) async throws -> AuthSuccessResponse
    func register(username: String, email: String, password: String) async throws -> AuthSuccessResponse
    func signInWithSocial(provider: String, providerId: String, token: String, fullName: String?, email: String?) async throws -> AuthSuccessResponse
}

@MainActor
class AuthService: NSObject, AuthServiceProtocol {
    
    private let baseURL = AppConfig.apiBaseURL + "/api/v0/user"
    
    // MARK: - Login & Register
    // Standart Login
    func login(credential: String, password: String) async throws -> AuthSuccessResponse {
        let endpoint = baseURL + "/login"
        let requestModel = LoginRequest(identifier: credential, password: password)
        
        return try await AF.request(endpoint, method: .post, parameters: requestModel, encoder: JSONParameterEncoder.default)
            .validate()
            .serializingDecodable(AuthSuccessResponse.self)
            .value
    }
    
    // Standart Register
    func register(username: String, email: String, password: String) async throws -> AuthSuccessResponse {
        let endpoint = baseURL + "/register"
        let requestModel = RegisterRequest(username: username, email: email, password: password)
        
        return try await AF.request(endpoint, method: .post, parameters: requestModel, encoder: JSONParameterEncoder.default)
            .validate()
            .serializingDecodable(AuthSuccessResponse.self)
            .value
    }
    
    // Hem Google hem de Apple için ortak sosyal giriş fonksiyonu
    func signInWithSocial(provider: String, providerId: String, token: String, fullName: String?, email: String?) async throws -> AuthSuccessResponse {
        // Önce sosyal giriş yapmayı dene
        let loginEndpoint = baseURL + "/social/login"
        let socialLoginRequest = SocialRequest(provider: provider, providerId: providerId, token: token, email: email, username: fullName)
        
        do {
            // Giriş yapmayı dene
            return try await AF.request(loginEndpoint, method: .post, parameters: socialLoginRequest, encoder: JSONParameterEncoder.default)
                .validate()
                .serializingDecodable(AuthSuccessResponse.self)
                .value
        } catch {
            print("Sosyal giriş başarısız, kayıt deneniyor... Hata: \(error)")
            
            let registerEndpoint = baseURL + "/social/register"
            let socialRegisterRequest = SocialRequest(provider: provider, providerId: providerId, token: token, email: email, username: fullName)
            
            return try await AF.request(registerEndpoint, method: .post, parameters: socialRegisterRequest, encoder: JSONParameterEncoder.default)
                .validate()
                .serializingDecodable(AuthSuccessResponse.self)
                .value
        }
    }
}

// MARK: - Apple Sign In Delegate Methods
extension AuthService: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Apple giriş ekranının nerede gösterecek
        return UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .flatMap { $0?.windows.first } ?? UIWindow()
    }
}

// Google'ın giriş ekranını sunabilmesi için bir extension
@MainActor
extension UIApplication {
    func topViewController() async -> UIViewController? {
        let keyWindow = self.connectedScenes
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)
        
        var topController = keyWindow?.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}
