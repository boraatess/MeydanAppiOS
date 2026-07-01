import Foundation

@MainActor
class ForgotPasswordViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading = false
    
    private let authFlowState: AuthenticationFlowState
    private let service: AuthServiceProtocol
    
    init(service: AuthServiceProtocol = AuthService(), authFlowState: AuthenticationFlowState) {
        self.service = service
        self.authFlowState = authFlowState
    }
    
    private func validateEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func sendPasswordResetRequest() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        guard !email.isEmpty else {
            errorMessage = "Lütfen e-posta adresinizi girin."
            isLoading = false
            return
        }
        guard validateEmail() else {
            errorMessage = "Lütfen geçerli bir e-posta adresi girin."
            isLoading = false
            return
        }
        
        do {
            let request = ForgotPasswordRequest(email: email)
            _ = try await service.forgotPassword(request: request)
            successMessage = "Parola sıfırlama talimatları \(email) adresine gönderildi."
            authFlowState.navigate(to: .verificationCode(email: email))
        } catch let error as NetworkError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Beklenmedik bir hata oluştu."
        }
        
        isLoading = false
    }
}
