import Foundation

// MARK: - /user/me Response Models
struct MeResponse: Decodable, Sendable {
    let status: String
    let user: MeUser
}
struct MeUser: Decodable, Sendable {
    let id: String?
    let _id: String?
    let fullName: String?
    let username: String?
    let email: String?
    let birthDate: String?
    let authProvider: String?
    let status: Int?
    let confirmed: Bool?
    let role: Int?
    let visible: Int?
    let profile: MeUserProfile?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case _id = "_id"
        case fullName, username, email, authProvider, status, confirmed, role, visible, profile, createdAt, updatedAt
        case birthDate = "birthday"
    }

    var resolvedId: String? {
        id ?? _id
    }
}

struct MeUserProfile: Decodable, Sendable {
    let bio: String?
    let avatar: String?
    let followers: [UserRelationshipReference]?
    let following: [UserRelationshipReference]?
    let hobbies: [String]?

    private enum CodingKeys: String, CodingKey {
        case bio, avatar, followers, following, hobbies
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bio = try? container.decode(String.self, forKey: .bio)
        avatar = try? container.decode(String.self, forKey: .avatar)
        followers = try? container.decode([UserRelationshipReference].self, forKey: .followers)
        following = try? container.decode([UserRelationshipReference].self, forKey: .following)
        hobbies = try? container.decode([String].self, forKey: .hobbies)
    }
}

struct UserRelationshipReference: Decodable, Sendable, Equatable {
    let id: String

    private enum CodingKeys: String, CodingKey {
        case id
        case _id
    }

    init(from decoder: Decoder) throws {
        if let id = try? decoder.singleValueContainer().decode(String.self) {
            self.id = id
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id))
            ?? (try? container.decode(String.self, forKey: ._id))
            ?? ""
    }
}

// MARK: - /user/my-favorites Response Models
struct FavoriteStreamersResponse: Decodable, Sendable {
    let status: String?
    let favorites: [FavoriteStreamerResponse]

    private enum CodingKeys: String, CodingKey {
        case status
        case favorites
        case users
        case results
        case data
    }

    init(from decoder: Decoder) throws {
        if let list = try? decoder.singleValueContainer().decode([FavoriteStreamerResponse].self) {
            status = nil
            favorites = list
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try? container.decode(String.self, forKey: .status)
        favorites = (try? container.decode([FavoriteStreamerResponse].self, forKey: .favorites))
            ?? (try? container.decode([FavoriteStreamerResponse].self, forKey: .users))
            ?? (try? container.decode([FavoriteStreamerResponse].self, forKey: .results))
            ?? (try? container.decode([FavoriteStreamerResponse].self, forKey: .data))
            ?? []
    }
}

struct FavoriteStreamerResponse: Decodable, Sendable {
    let id: String
    let fullName: String?
    let username: String?
    let profile: MeUserProfile?
    let isLive: Bool?
    let liveRoom: FavoriteLiveRoomResponse?

    private enum CodingKeys: String, CodingKey {
        case id
        case _id
        case fullName
        case name
        case username
        case profile
        case isLive
        case live
        case liveRoom
        case room
        case currentRoom
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id))
            ?? (try? container.decode(String.self, forKey: ._id))
            ?? UUID().uuidString
        fullName = (try? container.decode(String.self, forKey: .fullName))
            ?? (try? container.decode(String.self, forKey: .name))
        username = try? container.decode(String.self, forKey: .username)
        profile = try? container.decode(MeUserProfile.self, forKey: .profile)
        isLive = (try? container.decode(Bool.self, forKey: .isLive))
            ?? (try? container.decode(Bool.self, forKey: .live))
        liveRoom = (try? container.decode(FavoriteLiveRoomResponse.self, forKey: .liveRoom))
            ?? (try? container.decode(FavoriteLiveRoomResponse.self, forKey: .room))
            ?? (try? container.decode(FavoriteLiveRoomResponse.self, forKey: .currentRoom))
    }
}

struct FavoriteLiveRoomResponse: Decodable, Sendable {
    let id: String?
    let title: String?
    let status: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case _id
        case title
        case name
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id))
            ?? (try? container.decode(String.self, forKey: ._id))
        title = (try? container.decode(String.self, forKey: .title))
            ?? (try? container.decode(String.self, forKey: .name))
        status = try? container.decode(Int.self, forKey: .status)
    }
}
