import Foundation

struct UserProfile: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let username: String
    let bio: String
    let streamCount: Int
    let followersCount: Int
    let followingCount: Int
    let profileImageURL: String
    let email: String
    
    static let placeholder = UserProfile(
        id: "placeholder",
        name: "Yükleniyor...",
        username: "@user",
        bio: "",
        streamCount: 0,
        followersCount: 0,
        followingCount: 0,
        profileImageURL: "",
        email: ""
    )
}

struct PastBroadcast: Identifiable, Hashable {
    let id: String
    let title: String
    let date: String
    let duration: String
    let imageURL: String
    let username: String
    let profileImageURL: String

    init(
        id: String = UUID().uuidString,
        title: String,
        date: String,
        duration: String,
        imageURL: String,
        username: String = "",
        profileImageURL: String = ""
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.imageURL = imageURL
        self.username = username
        self.profileImageURL = profileImageURL
    }
}

struct ScheduledBroadcast: Identifiable, Hashable {
    let id: String
    let title: String
    let date: String
    let time: String
    let imageURL: String
    let scheduledDate: Date
    let categoryId: String?
    let categoryName: String?
    let username: String
    let profileImageURL: String

    init(
        id: String = UUID().uuidString,
        title: String,
        date: String,
        time: String,
        imageURL: String,
        scheduledDate: Date = Date(),
        categoryId: String? = nil,
        categoryName: String? = nil,
        username: String = "",
        profileImageURL: String = ""
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.time = time
        self.imageURL = imageURL
        self.scheduledDate = scheduledDate
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.username = username
        self.profileImageURL = profileImageURL
    }
}
