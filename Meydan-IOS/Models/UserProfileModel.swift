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
    let id = UUID()
    let title: String
    let date: String
    let duration: String
    let imageURL: String
}

struct ScheduledBroadcast: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let date: String
    let time: String
    let imageURL: String
}

