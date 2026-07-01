import Foundation

@MainActor
class ResetPasswordViewModel: ObservableObject {
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    @Published var hasMinLength = false
    @Published var hasUpperLowerCase = false
    @Published var hasNumber = false
    
    private let authFlowState: AuthenticationFlowState
    private let service: AuthServiceProtocol = AuthService()
    
    let email: String
    let token: String
    
    init(email: String, token: String, authFlowState: AuthenticationFlowState) {
        self.email = email
        self.token = token
        self.authFlowState = authFlowState
    }
    
    func navigateToRoot() {
        authFlowState.navigateToRoot()
    }
    
    func updateValidation() {
        hasMinLength = newPassword.count >= 8
        let hasUpper = newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLower = newPassword.range(of: "[a-z]", options: .regularExpression) != nil
        hasUpperLowerCase = hasUpper && hasLower
        hasNumber = newPassword.range(of: "[0-9]", options: .regularExpression) != nil
    }
    
    var isFormValid: Bool {
        return hasMinLength && hasUpperLowerCase && hasNumber && newPassword == confirmPassword
    }
    
    private func validatePassword() -> Bool {
        return hasMinLength && hasUpperLowerCase && hasNumber
    }
    
    func resetPassword() async {
        guard !newPassword.isEmpty else {
            errorMessage = "Lütfen yeni bir parola girin."
            return
        }
        guard validatePassword() else {
            errorMessage = "Şifreniz, 1 büyük karakter, 1 küçük karakter ve rakam içermelidir."
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Parolalar uyuşmuyor."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let request = ResetPasswordRequest(resetToken: token, newPassword: newPassword)
            _ = try await service.resetPassword(request: request)
            isSuccess = true
        } catch let error as NetworkError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Beklenmedik bir hata oluştu."
        }
        
        isLoading = false
    }
}

