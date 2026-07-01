
import Foundation
import SwiftUI

@MainActor
class DeleteAccountViewModel: ObservableObject {
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var step: Int = 1
    
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }
    
    func deleteAccount() async -> Bool {
        guard !password.isEmpty else {
            errorMessage = "Lütfen şifrenizi giriniz."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Şifreyi doğrula
            let checkRequest = CheckPasswordRequest(password: password)
            let checkResponse = try await authService.checkPassword(request: checkRequest)
            
            if checkResponse.isValid {
                // 2. Hesabı sil
                _ = try await authService.deleteAccount()
                isLoading = false
                step = 3 // Başarı adımı
                return true
            } else {
                isLoading = false
                errorMessage = "Şifre hatalı. Lütfen tekrar deneyiniz."
                return false
            }
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func goToStep2() {
        step = 2
    }
    
    func reset() {
        step = 1
        password = ""
        errorMessage = nil
    }
}
