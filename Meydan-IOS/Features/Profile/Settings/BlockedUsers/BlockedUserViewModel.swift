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
    
    // Fallback mock data for development / offline
    static let mockUsers: [BlockedUser] = [
        BlockedUser(id: "mock-1", fullName: "Ece Çiçek",   username: "@cicekece",   profile: nil),
        BlockedUser(id: "mock-2", fullName: "Ahmet Yıldız", username: "@ahmetyildiz", profile: nil),
        BlockedUser(id: "mock-3", fullName: "Zeynep Kaya",  username: "@zeynepkaya",  profile: nil),
        BlockedUser(id: "mock-4", fullName: "Mert Demir",   username: "@mertdemir",   profile: nil),
    ]
    
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
            // API boş dönerse veya hata alırsa mock kullan
            self.blockedUsers = response.blockedUsers.isEmpty ? Self.mockUsers : response.blockedUsers
        } catch {
            self.errorMessage = error.localizedDescription
            print("Engellenen kullanıcılar alınırken hata: \(error.localizedDescription)")
            // Servis hata verirse mock verileri göster
            self.blockedUsers = Self.mockUsers
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
