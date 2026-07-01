import Foundation

struct UserSearchResponse: Decodable, Sendable {
    let users: [FavoriteStreamerResponse]
    let rooms: [RoomResponse]

    private enum CodingKeys: String, CodingKey {
        case users
        case people
        case favorites
        case streamers
        case rooms
        case chats
        case results
        case data
    }

    init(from decoder: Decoder) throws {
        if let list = try? decoder.singleValueContainer().decode([FavoriteStreamerResponse].self) {
            users = list
            rooms = []
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        var decodedUsers = (try? container.decode([FavoriteStreamerResponse].self, forKey: .users))
            ?? (try? container.decode([FavoriteStreamerResponse].self, forKey: .people))
            ?? (try? container.decode([FavoriteStreamerResponse].self, forKey: .favorites))
            ?? (try? container.decode([FavoriteStreamerResponse].self, forKey: .streamers))
            ?? []

        var decodedRooms = (try? container.decode([RoomResponse].self, forKey: .rooms))
            ?? (try? container.decode([RoomResponse].self, forKey: .chats))
            ?? []

        if decodedUsers.isEmpty, decodedRooms.isEmpty, let nested = try? container.decode(UserSearchNestedResults.self, forKey: .results) {
            decodedUsers = nested.users
            decodedRooms = nested.rooms
        } else if decodedUsers.isEmpty, decodedRooms.isEmpty, let nested = try? container.decode(UserSearchNestedResults.self, forKey: .data) {
            decodedUsers = nested.users
            decodedRooms = nested.rooms
        }

        users = decodedUsers
        rooms = decodedRooms
    }
}

private struct UserSearchNestedResults: Decodable, Sendable {
    let users: [FavoriteStreamerResponse]
    let rooms: [RoomResponse]

    private enum CodingKeys: String, CodingKey {
        case users
        case people
        case favorites
        case streamers
        case rooms
        case chats
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        users = (try? container.decode([FavoriteStreamerResponse].self, forKey: .users))
            ?? (try? container.decode([FavoriteStreamerResponse].self, forKey: .people))
            ?? (try? container.decode([FavoriteStreamerResponse].self, forKey: .favorites))
            ?? (try? container.decode([FavoriteStreamerResponse].self, forKey: .streamers))
            ?? []
        rooms = (try? container.decode([RoomResponse].self, forKey: .rooms))
            ?? (try? container.decode([RoomResponse].self, forKey: .chats))
            ?? []
    }
}

struct UserSearchQuery: Encodable, Sendable {
    let q: String
}
