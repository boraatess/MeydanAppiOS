// //  BlockedUserViewModel.swift
//  Meydan-IOS
//
//  Created by bora ateş on 24.04.2026.
//

import Foundation

@MainActor
class BlockedUserViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var blockedUsers: [BlockedUser] = []
    @Published var errorMessage: String?
    
    init() {
        Task {
            await getBlockedUsers()
        }
    }
    
    func getBlockedUsers() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let response = try await UserService.shared.getBlockedUsers()
            self.blockedUsers = response.blockedUsers
        } catch {
            self.errorMessage = error.localizedDescription
            print("Engellenen kullanıcılar alınırken hata: \(error.localizedDescription)")
            self.blockedUsers = []
        }
    }
    
    func unblockUser(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // try await UserService.shared.unblockUser(userId: userId)
            let response = try await UserService.shared.unblockUser(with: userId)
            print(response)
            blockedUsers.removeAll { $0.id == userId }
            
        } catch {
            self.errorMessage = error.localizedDescription
            
        }
    }
}
