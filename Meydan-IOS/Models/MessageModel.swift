import Foundation

enum AuthorRole: String, Codable {
    case user
    case moderator
    case chatOwner
}

struct Message: Identifiable, Codable, Hashable {
    var id: String? // RTDB'nin oluşturduğu auto-id buraya atanacak
    let text: String
    let senderId: String?
    let username: String?
    let authorName: String?
    let authorAvatar: String? // Avatar URL or image name
    let authorRole: AuthorRole
    let timestamp: String
    var createdAt: Double? // RTDB timestamp'i milisaniye (Double/Int) olarak tutar
    var isCurrentUser: Bool = false

    private enum CodingKeys: String, CodingKey {
        case id, text, senderId, username, authorName, authorAvatar, authorRole, timestamp, createdAt
    }

    init(
        id: String? = nil,
        text: String,
        senderId: String? = nil,
        username: String? = nil,
        authorName: String?,
        authorAvatar: String?,
        authorRole: AuthorRole,
        timestamp: String,
        createdAt: Double? = nil,
        isCurrentUser: Bool = false
    ) {
        self.id = id
        self.text = text
        self.senderId = senderId
        self.username = username
        self.authorName = authorName
        self.authorAvatar = authorAvatar
        self.authorRole = authorRole
        self.timestamp = timestamp
        self.createdAt = createdAt
        self.isCurrentUser = isCurrentUser
    }
    
    var isSentByUser: Bool {
        isCurrentUser || (senderId == nil && authorName == nil)
    }

    var resolvedUsername: String? {
        username ?? authorName
    }
}
