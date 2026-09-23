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
    let avatar: String?
    let isLive: Bool?
    let liveRoom: FavoriteLiveRoomResponse?
    let broadcastTitle: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case _id
        case title
        case fullName
        case name
        case username
        case profile
        case avatar
        case image
        case imageUrl
        case profileImage
        case profileImageURL
        case user
        case streamer
        case favoriteStreamer
        case publisher
        case host
        case isLive
        case live
        case liveRoom
        case room
        case currentRoom
        case activeRoom
        case currentStream
        case liveStream
        case stream
        case broadcast
        case activeBroadcast
        case rooms
        case roomTitle
        case liveTitle
        case streamTitle
        case broadcastTitle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nestedUser = (try? container.decode(FavoriteStreamerResponse.self, forKey: .user))
            ?? (try? container.decode(FavoriteStreamerResponse.self, forKey: .streamer))
            ?? (try? container.decode(FavoriteStreamerResponse.self, forKey: .favoriteStreamer))
            ?? (try? container.decode(FavoriteStreamerResponse.self, forKey: .publisher))
            ?? (try? container.decode(FavoriteStreamerResponse.self, forKey: .host))

        id = (try? container.decode(String.self, forKey: .id))
            ?? (try? container.decode(String.self, forKey: ._id))
            ?? nestedUser?.id
            ?? UUID().uuidString
        fullName = (try? container.decode(String.self, forKey: .fullName))
            ?? (try? container.decode(String.self, forKey: .name))
            ?? nestedUser?.fullName
        username = (try? container.decode(String.self, forKey: .username))
            ?? nestedUser?.username
        profile = (try? container.decode(MeUserProfile.self, forKey: .profile))
            ?? nestedUser?.profile
        avatar = (try? container.decode(String.self, forKey: .avatar))
            ?? (try? container.decode(String.self, forKey: .image))
            ?? (try? container.decode(String.self, forKey: .imageUrl))
            ?? (try? container.decode(String.self, forKey: .profileImage))
            ?? (try? container.decode(String.self, forKey: .profileImageURL))
            ?? nestedUser?.avatar
        isLive = (try? container.decode(Bool.self, forKey: .isLive))
            ?? (try? container.decode(Bool.self, forKey: .live))
            ?? nestedUser?.isLive
        let directLiveRoom = try? container.decode(FavoriteLiveRoomResponse.self, forKey: .liveRoom)
        let room = try? container.decode(FavoriteLiveRoomResponse.self, forKey: .room)
        let currentRoom = try? container.decode(FavoriteLiveRoomResponse.self, forKey: .currentRoom)
        let activeRoom = try? container.decode(FavoriteLiveRoomResponse.self, forKey: .activeRoom)
        let currentStream = try? container.decode(FavoriteLiveRoomResponse.self, forKey: .currentStream)
        let liveStream = try? container.decode(FavoriteLiveRoomResponse.self, forKey: .liveStream)
        let stream = try? container.decode(FavoriteLiveRoomResponse.self, forKey: .stream)
        let broadcast = try? container.decode(FavoriteLiveRoomResponse.self, forKey: .broadcast)
        let activeBroadcast = try? container.decode(FavoriteLiveRoomResponse.self, forKey: .activeBroadcast)
        let rooms = try? container.decode([FavoriteLiveRoomResponse].self, forKey: .rooms)
        let liveRoomFromRooms = rooms?.first(where: { $0.status == 1 }) ?? rooms?.first

        if let directLiveRoom {
            liveRoom = directLiveRoom
        } else if let room {
            liveRoom = room
        } else if let currentRoom {
            liveRoom = currentRoom
        } else if let activeRoom {
            liveRoom = activeRoom
        } else if let currentStream {
            liveRoom = currentStream
        } else if let liveStream {
            liveRoom = liveStream
        } else if let stream {
            liveRoom = stream
        } else if let broadcast {
            liveRoom = broadcast
        } else if let activeBroadcast {
            liveRoom = activeBroadcast
        } else if let liveRoomFromRooms {
            liveRoom = liveRoomFromRooms
        } else {
            liveRoom = nestedUser?.liveRoom
        }

        let roomTitle = try? container.decode(String.self, forKey: .roomTitle)
        let liveTitle = try? container.decode(String.self, forKey: .liveTitle)
        let streamTitle = try? container.decode(String.self, forKey: .streamTitle)
        let directBroadcastTitle = try? container.decode(String.self, forKey: .broadcastTitle)
        let topLevelTitle = try? container.decode(String.self, forKey: .title)

        if let roomTitle {
            broadcastTitle = roomTitle
        } else if let liveTitle {
            broadcastTitle = liveTitle
        } else if let streamTitle {
            broadcastTitle = streamTitle
        } else if let directBroadcastTitle {
            broadcastTitle = directBroadcastTitle
        } else if let topLevelTitle {
            broadcastTitle = topLevelTitle
        } else {
            broadcastTitle = nestedUser?.broadcastTitle
        }
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
        case roomTitle
        case liveTitle
        case streamTitle
        case broadcastTitle
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id))
            ?? (try? container.decode(String.self, forKey: ._id))
        let titleValue = try? container.decode(String.self, forKey: .title)
        let nameValue = try? container.decode(String.self, forKey: .name)
        let roomTitle = try? container.decode(String.self, forKey: .roomTitle)
        let liveTitle = try? container.decode(String.self, forKey: .liveTitle)
        let streamTitle = try? container.decode(String.self, forKey: .streamTitle)
        let broadcastTitle = try? container.decode(String.self, forKey: .broadcastTitle)

        title = titleValue
            ?? nameValue
            ?? roomTitle
            ?? liveTitle
            ?? streamTitle
            ?? broadcastTitle
        status = try? container.decode(Int.self, forKey: .status)
    }
}
