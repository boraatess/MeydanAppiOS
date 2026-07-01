import Foundation

enum AuthorRole: String, Codable {
    case user
    case moderator
    case chatOwner
}

struct Message: Identifiable, Codable, Hashable {
    var id: String? // RTDB'nin oluşturduğu auto-id buraya atanacak
    let text: String
    let authorName: String? /// if nil, message is sent by user
    let authorAvatar: String? // Avatar URL or image name
    let authorRole: AuthorRole
    let timestamp: String
    var createdAt: Double? // RTDB timestamp'i milisaniye (Double/Int) olarak tutar
    
    var isSentByUser: Bool {
        return authorName == nil
    }
}
