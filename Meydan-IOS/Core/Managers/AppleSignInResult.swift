import Foundation
import AuthenticationServices
import UIKit

// Apple'dan gelen başarılı giriş sonucunu tutacak model
struct AppleSignInResult {
    let providerId: String
    let fullName: String?
    let email: String?
    let token: String
}

@MainActor
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?

    func signIn() async throws -> AppleSignInResult {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
    
    // MARK: - Delegate Methods
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Aktif olan pencereyi bulup Apple giriş ekranını onun üzerinde göstermesini sağlar
        return UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .flatMap { $0?.windows.first } ?? UIWindow()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIdTokenData = appleIDCredential.identityToken,
              let appleIdToken = String(data: appleIdTokenData, encoding: .utf8) else {
            continuation?.resume(throwing: NetworkError.unknown(URLError(.badServerResponse)))
            return
        }
        
        let fullName = (appleIDCredential.fullName?.givenName ?? "") + " " + (appleIDCredential.fullName?.familyName ?? "")
        
        let result = AppleSignInResult(
            providerId: appleIDCredential.user,
            fullName: fullName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : fullName,
            email: appleIDCredential.email,
            token: appleIdToken
        )
        
        continuation?.resume(returning: result)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
    }
}
