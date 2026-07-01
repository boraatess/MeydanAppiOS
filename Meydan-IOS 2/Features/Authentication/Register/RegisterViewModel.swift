import Foundation
import SwiftUICore

@MainActor
class RegisterViewModel: ObservableObject {
    
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private var authManager: AuthenticationManager
    private let service: AuthServiceProtocol
    
    init(service: AuthServiceProtocol, authManager: AuthenticationManager) {
        self.service = service
        self.authManager = authManager
    }
    
    func register() async {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Lütfen tüm alanları doldurun."
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Şifreler uyuşmuyor."
            return
        }
        
        isLoading = true
        errorMessage = nil

        do {
            let response = try await service.register(username: username, email: email, password: password)
            print("Kayıt başarılı! Token: \(response.token)")
            authManager.login(token: response.token)
        } catch {
            self.errorMessage = "Kayıt sırasında bir hata oluştu."
        }
        
        isLoading = false
    }
}
