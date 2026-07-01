import Foundation
import Combine
import SwiftUI

@MainActor
class CreateRoomViewModel: ObservableObject {
    
    @Published var hobbies: [Hobby] = []
    @Published var isLoadingHobbies = false
    @Published var errorMessage: String?
    @Published var selectedImage: UIImage?
    @Published var isLoading: Bool = false
    @Published var imageURL: String = ""
    @Published var createdRoomId: String?

    
    private let hobbiesService: HobbiesServiceProtocol
    private let roomService: RoomServiceProtocol
    private let uploadService: UploadServiceProtocol
    
    init(
        hobbiesService: HobbiesServiceProtocol = HobbiesService(baseURL: AppConfig.apiBaseURL),
        roomService: RoomServiceProtocol = RoomService.shared,
        uploadService: UploadServiceProtocol = UploadService.shared
    ) {
        self.hobbiesService = hobbiesService
        self.roomService = roomService
        self.uploadService = uploadService
    }
    
    func fetchHobbies() {
        isLoadingHobbies = true
        errorMessage = nil
        Task {
            do {
                let response = try await hobbiesService.fetchAllHobbies()
                self.hobbies = response.hobbies
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoadingHobbies = false
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
            let uploadedURL = try await UploadService.shared.uploadImage(imageData: imageData, fileName: .room)
            
            self.selectedImage = image
            self.imageURL = uploadedURL
            
            
            print("yayın fotografi basariyla yuklendi: \(uploadedURL)")
            
        } catch {
            print("yayın fotografi yuklenirken hata: \(error.localizedDescription)")
        }
        
    }

    func createRoom(title: String, date: Date, categoryName: String, selectedImage: UIImage?) async -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            errorMessage = "Yayın başlığı boş olamaz."
            return false
        }

        guard let categoryId = hobbies.first(where: { $0.name == categoryName })?._id else {
            errorMessage = "Lütfen bir kategori seçin."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let uploadedImageURL = try await uploadImageIfNeeded(selectedImage)
            let request = CreateRoomRequest(
                title: trimmedTitle,
                category: categoryId,
                date: Self.iso8601Formatter.string(from: date),
                image: uploadedImageURL ?? ""
            )

            let response = try await roomService.createRoom(request: request)
            createdRoomId = response.roomId
            imageURL = uploadedImageURL ?? ""
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func startRoom(id: String) async -> Bool {
        let roomId = id.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !roomId.isEmpty else {
            errorMessage = "Oda ID bulunamadı."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await roomService.startRoom(id: roomId)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func endRoom(id: String) async -> Bool {
        let roomId = id.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !roomId.isEmpty else {
            errorMessage = "Oda ID bulunamadı."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await roomService.endRoom(id: roomId)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func uploadImageIfNeeded(_ image: UIImage?) async throws -> String? {
        guard let image else { return nil }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.serverError(message: "Seçilen görsel JPEG formatına dönüştürülemedi.")
        }

        return try await uploadService.uploadImage(
            imageData: imageData,
            fileName: .room,
            mimeType: "image/jpeg",
            fieldName: "image",
            endpointPath: "/brand/upload"
        )
    }

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
