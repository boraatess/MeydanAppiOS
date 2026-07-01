import Foundation
import SwiftUI

@MainActor
class EmailUpdateViewModel: ObservableObject {
    @Published var newEmail = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    @Published var navigateToVerification = false
    
    private let authService: AuthServiceProtocol
    private let authFlowState: AuthenticationFlowState
    
    init(authService: AuthServiceProtocol = AuthService(), authFlowState: AuthenticationFlowState = AuthenticationFlowState()) {
        self.authService = authService
        self.authFlowState = authFlowState
    }
    func updateEmail() async -> Bool {
        guard !newEmail.isEmpty else {
            errorMessage = "Lütfen tüm alanları doldurunuz."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }
        
        do {
            let request = RequestEmailUpdateRequest(newEmail: newEmail)
            _ = try await authService.requestEmailUpdate(request: request)
            successMessage = "Doğrulama kodu e-posta adresinize gönderildi."
            navigateToVerification = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

struct UpdateEmailRequest: Encodable, Sendable {
    let password: String
    let newEmail: String
    let code: String?
}
