//
//  DeactiveAccountVM.swift
//  Meydan-IOS
//
//  Created by bora ateş on 24.04.2026.
//

import Foundation



class DeactiveAccountVM: ObservableObject {
    
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isDeactivated = false
    
    func deactivateAccount() async -> Bool {
        guard !password.isEmpty else {
            errorMessage = "Lütfen şifrenizi giriniz."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let request = DisableAccountRequest(password: password)
            _ = try await UserService.shared.disableAccount(request: request)
            isDeactivated = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
        
    }
    
    
}
