import Foundation

struct CreateRoomRequest: Encodable, Sendable {
    let title: String
    let category: String
    let date: String
    let image: String
}

struct CreateRoomResponse: Decodable, Sendable {
    let status: String?
    let roomId: String?
    let message: String?
}

struct UpdateRoomRequest: Encodable, Sendable {
    let title: String
    let category: String
    let date: String
    let image: String
}

struct UpdateRoomResponse: Decodable, Sendable {
    let status: String?
    let message: String?
    let room: RoomResponse?
    let roomId: String?
}

struct RoomStatusResponse: Decodable, Sendable {
    let status: String?
    let message: String?
}

struct RoomAccessResponse: Decodable, Sendable {
    let status: String?
    let message: String?
    let allowed: Bool?
    let canAccess: Bool?
    let hasAccess: Bool?
    let access: Bool?
    let isAllowed: Bool?

    var isAccessible: Bool {
        if let allowed { return allowed }
        if let canAccess { return canAccess }
        if let hasAccess { return hasAccess }
        if let access { return access }
        if let isAllowed { return isAllowed }

        if let status {
            let normalized = status.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            if normalized == "OK" || normalized == "SUCCESS" || normalized == "ALLOWED" {
                return true
            }
            if normalized == "DENIED" || normalized == "FORBIDDEN" || normalized == "ERROR" {
                return false
            }
        }

        return true
    }
}

struct EndRoomResponse: Decodable, Sendable {
    let status: String?
    let finalViewersCount: Int?
    let message: String?
}

struct EndRoomRequest: Encodable, Sendable {
    let roomId: String
    let immediate: Bool
}

struct RoomViewersMutationRequest: Encodable, Sendable {
    let roomId: String
    let id: String

    init(roomId: String) {
        self.roomId = roomId
        self.id = roomId
    }
}

struct UserRoomsResponse: Decodable, Sendable {
    let status: String?
    let count: Int?
    let rooms: [RoomResponse]

    private enum CodingKeys: String, CodingKey {
        case status
        case count
        case rooms
        case data
        case results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try? container.decode(String.self, forKey: .status)
        self.count = try? container.decode(Int.self, forKey: .count)
        
        if let rooms = try? container.decode([RoomResponse].self, forKey: .rooms) {
            self.rooms = rooms
        } else if let rooms = try? container.decode([RoomResponse].self, forKey: .data) {
            self.rooms = rooms
        } else if let rooms = try? container.decode([RoomResponse].self, forKey: .results) {
            self.rooms = rooms
        } else {
            self.rooms = []
        }
    }
}

struct RoomSingleResponse: Decodable, Sendable {
    let room: RoomResponse

    private enum CodingKeys: String, CodingKey {
        case room
        case data
        case result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let room = try? container.decode(RoomResponse.self, forKey: .room) {
            self.room = room
        } else if let room = try? container.decode(RoomResponse.self, forKey: .data) {
            self.room = room
        } else if let room = try? container.decode(RoomResponse.self, forKey: .result) {
            self.room = room
        } else {
            let room = try RoomResponse(from: decoder)
            guard !room._id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DecodingError.valueNotFound(
                    RoomResponse.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Room response did not contain a valid room id."
                    )
                )
            }
            self.room = room
        }
    }
}

struct RoomInviteRequest: Encodable, Sendable {
    let roomId: String
    let username: String
}

struct RoomMentionNotificationRequest: Encodable, Sendable {
    let roomId: String
    let targetUserId: String
    let messagePreview: String
}

struct RoomActionResponse: Decodable, Sendable {
    let status: String?
    let message: String?
}

struct RoomExploreResponse: Decodable, Sendable {
    let status: String?
    let currentPage: Int?
    let feed: RoomExploreFeed?
}

struct RoomExploreFeed: Decodable, Sendable {
    let forYou: [RoomResponse]
    let trending: [RoomResponse]
    let suggestedStreamers: [HostResponse]
}

struct RoomExploreQuery: Encodable, Sendable {
    let page: Int
    let limit: Int
}

struct CreatePollRequest: Encodable, Sendable {
    let roomId: String
    let question: String
    let options: [String]
}

struct CreatePollResponse: Decodable, Sendable {
    let status: String?
    let message: String?
}

struct VotePollRequest: Encodable, Sendable {
    let roomId: String
    let optionId: Int
}

struct VotePollResponse: Decodable, Sendable {
    let status: String?
    let message: String?
}

struct ShareURLResponse: Decodable, Sendable {
    let url: String?
    let shareUrl: String?
    let link: String?

    /// Backend hangi key'i döndürse döndürsün URL'i çözer
    var resolvedURL: String? {
        url ?? shareUrl ?? link
    }
}

struct RoomViewersResponse: Decodable, Sendable {
    let status: String?
    let count: Int?
    let viewers: [HostResponse]

    private enum CodingKeys: String, CodingKey {
        case status
        case count
        case viewers
        case data
        case results
        case users
    }

    init(from decoder: Decoder) throws {
        if let list = try? decoder.singleValueContainer().decode([HostResponse].self) {
            status = nil
            count = list.count
            viewers = list
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try? container.decode(String.self, forKey: .status)
        count = try? container.decode(Int.self, forKey: .count)
        viewers = (try? container.decode([HostResponse].self, forKey: .viewers))
            ?? (try? container.decode([HostResponse].self, forKey: .data))
            ?? (try? container.decode([HostResponse].self, forKey: .results))
            ?? (try? container.decode([HostResponse].self, forKey: .users))
            ?? []
    }
}

struct BanRoomUserRequest: Encodable, Sendable {
    let roomId: String
    let userIdToBan: String
}
