import Foundation
import SwiftUI
import UIKit

@MainActor
class PersonalInfoViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var bio: String = ""
    @Published var birthDate: String = ""
    @Published var profileImageURL: String = ""
    @Published var selectedProfileImage: UIImage?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let calendar = Calendar(identifier: .gregorian)
    private let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private let serverDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    init(user: UserProfile? = nil) {
        if let user = user {
            self.name = user.name
            self.username = displayUsername(from: user.username)
            self.bio = user.bio
            self.profileImageURL = user.profileImageURL
        }
        
        Task {
            await fetchUserData()
        }
    }
    
    /*
     {
       "username": "string",
       "fullName": "string",
       "bio": "string",
       "avatar": "string",
       "birthday": "string"
     }
     
     */
    
    func updateUserData() async {
        isLoading = true
    }
    
    func fetchUserData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await AuthService.shared.getMe()
            let user = response.user
            
            self.name = user.fullName ?? ""
            self.username = displayUsername(from: user.username ?? "")
            self.bio = user.profile?.bio ?? ""
            self.birthDate = displayBirthdayString(from: user.birthDate ?? "")
            self.profileImageURL = user.profile?.avatar ?? ""
            self.selectedProfileImage = nil
        } catch {
            print("Kişisel bilgiler alınırken hata: \(error.localizedDescription)")
        }
    }

    func uploadSelectedImage(_ image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Secilen gorsel JPEG formatina donusturulemedi")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let uploadedURL = try await UserService.shared.uploadProfileImage(imageData: imageData, fileName: .avatar)
            self.selectedProfileImage = image
            self.profileImageURL = uploadedURL
            print("Profil fotografi basariyla yuklendi: \(uploadedURL)")
            
            // Fotoğraf yüklendiğinde otomatik olarak backend'e de kaydet
            await updateProfile()
        } catch {
            print("Profil fotografi yuklenirken hata: \(error.localizedDescription)")
        }
    }
    
    func updateProfile() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let normalizedBirthday = normalizedBirthdayString(from: birthDate)

        if !normalizedBirthday.isEmpty, !isAtLeast15YearsOld(birthday: normalizedBirthday) {
            errorMessage = "Uygulamamizi yalnizca 15 yas ve uzerindeki kisiler kullanabilir."
            return
        }
        
        let normalizedUsername = normalizedUsernameString(from: username)
        
        let request = UpdateProfileRequest(
            username: normalizedUsername,
            fullName: name,
            bio: bio,
            avatar: profileImageURL,
            birthday: normalizedBirthday
        )
        
        print("update profile request : \(request)")
        
        do {
            _ = try await UserService.shared.updateProfile(request: request)
            print("Profil başarıyla güncellendi")
            // Refresh local data to be sure
            await fetchUserData()
            
        } catch {
            errorMessage = error.localizedDescription
            print("Profil güncellenirken hata: \(error.localizedDescription)")
        }
    }

    private func normalizedBirthdayString(from value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedValue.isEmpty else {
            return trimmedValue
        }

        if let date = displayDateFormatter.date(from: trimmedValue) {
            return serverDateFormatter.string(from: date)
        }

        if let date = serverDateFormatter.date(from: trimmedValue) {
            return serverDateFormatter.string(from: date)
        }

        if let date = iso8601Formatter.date(from: trimmedValue) {
            return serverDateFormatter.string(from: date)
        }

        return trimmedValue
    }

    private func displayBirthdayString(from value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedValue.isEmpty else {
            return ""
        }

        if let date = serverDateFormatter.date(from: trimmedValue) {
            return displayDateFormatter.string(from: date)
        }

        if let date = displayDateFormatter.date(from: trimmedValue) {
            return displayDateFormatter.string(from: date)
        }

        if let date = iso8601Formatter.date(from: trimmedValue) {
            return displayDateFormatter.string(from: date)
        }

        return trimmedValue
    }

    private func displayUsername(from value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedValue.isEmpty else {
            return ""
        }

        return trimmedValue.hasPrefix("@") ? trimmedValue : "@\(trimmedValue)"
    }

    private func normalizedUsernameString(from value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
    }

    var birthDatePickerValue: Date {
        if let date = displayDateFormatter.date(from: birthDate) {
            return date
        }

        if let date = serverDateFormatter.date(from: birthDate) {
            return date
        }

        if let date = iso8601Formatter.date(from: birthDate) {
            return date
        }

        let adultReferenceDate = calendar.date(byAdding: .year, value: -18, to: Date())
        return adultReferenceDate ?? Date()
    }

    var latestAllowedBirthDate: Date {
        calendar.date(byAdding: .year, value: -15, to: Date()) ?? Date()
    }

    func setBirthDate(_ date: Date) {
        let clampedDate = min(date, latestAllowedBirthDate)
        birthDate = displayDateFormatter.string(from: clampedDate)
        errorMessage = nil
    }

    private func isAtLeast15YearsOld(birthday: String) -> Bool {
        guard let birthDate = serverDateFormatter.date(from: birthday) else {
            return false
        }

        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return (ageComponents.year ?? 0) >= 15
    }
}
