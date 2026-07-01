import Foundation
import SwiftUI

@MainActor
class ContactUsViewModel: ObservableObject {
    @Published var selectedTopic: String = "Teknik Sorun"
    @Published var message: String = ""
    @Published var selectedImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSubmitted = false
    
    private let authService: AuthServiceProtocol
    private let uploadService: UploadServiceProtocol
    
    init(authService: AuthServiceProtocol = AuthService(), 
         uploadService: UploadServiceProtocol = UploadService()) {
        self.authService = authService
        self.uploadService = uploadService
    }
    
    func submitSupport() async {
        guard !message.isEmpty else {
            errorMessage = "Lütfen bir mesaj yazınız."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            var imageUrls: [String] = []
            
            // 1. Varsa fotoğrafı yükle
            if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.7) {
                let uploadedUrl = try await uploadService.uploadImage(
                    imageData: imageData,
                    fileName: .report,
                    mimeType: "image/jpeg",
                    fieldName: "file",
                    endpointPath: "/brand/upload"
                )
                imageUrls.append(uploadedUrl)
            }
            
            // 2. Destek talebini oluştur
            let request = SupportRequest(
                subject: selectedTopic,
                message: message,
                images: imageUrls
            )
            
            _ = try await authService.createSupport(request: request)
            
            isLoading = false
            withAnimation {
                isSubmitted = true
            }
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
