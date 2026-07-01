import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case decodingFailed(Error)
    case serverError(message: String)
    case unknown(Error)
    
    // Kullanıcıya gösterilecek hata mesajları
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz API adresi."
        case .decodingFailed:
            return "Sunucudan gelen veri işlenemedi."
        case .serverError(let message):
            return message
        case .unknown:
            return "Bilinmeyen bir hata oluştu."
        }
    }
}
