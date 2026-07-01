import Foundation
import SwiftUI

@MainActor
class PasswordRenewalViewModel: ObservableObject {
    
    @Published var currentPassword = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var step: Int = 1

    @Published var hasMinLength = false
    @Published var hasUpperLowerCase = false
    @Published var hasNumber = false
    
    func checkCurrentPassword() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let request = CheckPasswordRequest(password: currentPassword)
            let response = try await AuthService.shared.checkPassword(request: request)
            if response.isValid {
                step = 2
                return true
            } else {
                errorMessage = "Parola yanlış."
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateValidation() {
        hasMinLength = newPassword.count >= 8
        let hasUpper = newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLower = newPassword.range(of: "[a-z]", options: .regularExpression) != nil
        hasUpperLowerCase = hasUpper && hasLower
        hasNumber = newPassword.range(of: "[0-9]", options: .regularExpression) != nil
    }

    var isNewPasswordValid: Bool {
        hasMinLength && hasUpperLowerCase && hasNumber
    }
    
    func updatePassword() async -> Bool {
        guard !newPassword.isEmpty else {
            errorMessage = "Lutfen yeni bir parola girin."
            return false
        }

        guard isNewPasswordValid else {
            errorMessage = "Sifreniz, 1 buyuk karakter, 1 kucuk karakter ve rakam icermelidir."
            return false
        }

        guard newPassword == confirmPassword else {
            errorMessage = "Parolalar eslesmiyor."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let request = SetPasswordRequest(oldPass: currentPassword, newPass: newPassword)
            _ = try await AuthService.shared.setPassword(request: request)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

struct SetPasswordRequest: Encodable, Sendable {
    let oldPass: String
    let newPass: String
}

struct CheckPasswordRequest: Encodable, Sendable {
    let password: String
}

struct CheckPasswordResponse: Decodable, Sendable {
    let status: String?
    let message: String?
    let accessPermitToken: String?

    var isValid: Bool {
        if let status, status.uppercased() == "OK" {
            return true
        }

        return !(accessPermitToken?.isEmpty ?? true)
    }
}
