import Foundation

enum NotificationButtonStyle {
    case none
    case active
    case disabled
}

struct NotificationItem: Identifiable, Equatable {
    let id: String
    let imageUrl: String
    let title: String
    let message: String
    let time: String
    var isRead: Bool
    var buttonTitle: String? = nil
    var buttonStyle: NotificationButtonStyle = .none
    let roomId: String?
    let type: String?
    let createdAt: Date?
}

// MARK: - API Models

struct FCMSubscribeRequest: Encodable, Sendable {
    let fcmToken: String
}

struct RoomNotificationRequest: Encodable, Sendable {
    let fcmToken: String
    let roomId: String
}

struct NotificationActionResponse: Decodable, Sendable {
    let success: Bool?
    let status: String?
    let message: String?
}

struct NotificationsListResponse: Decodable, Sendable {
    let status: String?
    let count: Int?
    let notifications: [NotificationResponse]

    private enum CodingKeys: String, CodingKey {
        case status
        case count
        case notifications
        case data
        case results
    }

    init(from decoder: Decoder) throws {
        if let list = try? decoder.singleValueContainer().decode([NotificationResponse].self) {
            status = nil
            count = list.count
            notifications = list
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try? container.decode(String.self, forKey: .status)
        count = try? container.decode(Int.self, forKey: .count)

        if let items = try? container.decode([NotificationResponse].self, forKey: .notifications) {
            notifications = items
        } else if let items = try? container.decode([NotificationResponse].self, forKey: .data) {
            notifications = items
        } else if let items = try? container.decode([NotificationResponse].self, forKey: .results) {
            notifications = items
        } else if let nested = try? container.decode(NotificationsNestedResponse.self, forKey: .data) {
            notifications = nested.notifications
        } else if let nested = try? container.decode(NotificationsNestedResponse.self, forKey: .results) {
            notifications = nested.notifications
        } else {
            notifications = []
        }
    }
}

private struct NotificationsNestedResponse: Decodable, Sendable {
    let notifications: [NotificationResponse]

    private enum CodingKeys: String, CodingKey {
        case notifications
        case items
        case list
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notifications = (try? container.decode([NotificationResponse].self, forKey: .notifications))
            ?? (try? container.decode([NotificationResponse].self, forKey: .items))
            ?? (try? container.decode([NotificationResponse].self, forKey: .list))
            ?? []
    }
}

struct NotificationResponse: Decodable, Sendable {
    let id: String
    let type: String?
    let title: String?
    let message: String?
    let body: String?
    let content: String?
    let isRead: Bool?
    let read: Bool?
    let createdAt: String?
    let roomId: String?
    let room: NotificationRoomResponse?
    let sender: HostResponse?
    let user: HostResponse?
    let actor: HostResponse?

    private enum CodingKeys: String, CodingKey {
        case id
        case _id
        case type
        case notificationType
        case title
        case message
        case body
        case content
        case isRead
        case read
        case createdAt
        case roomId
        case room
        case sender
        case user
        case actor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id))
            ?? (try? container.decode(String.self, forKey: ._id))
            ?? UUID().uuidString
        type = (try? container.decode(String.self, forKey: .type))
            ?? (try? container.decode(String.self, forKey: .notificationType))
        title = try? container.decode(String.self, forKey: .title)
        message = (try? container.decode(String.self, forKey: .message))
            ?? (try? container.decode(String.self, forKey: .body))
            ?? (try? container.decode(String.self, forKey: .content))
        body = try? container.decode(String.self, forKey: .body)
        content = try? container.decode(String.self, forKey: .content)
        isRead = (try? container.decode(Bool.self, forKey: .isRead))
            ?? (try? container.decode(Bool.self, forKey: .read))
        read = try? container.decode(Bool.self, forKey: .read)
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        roomId = try? container.decode(String.self, forKey: .roomId)
        room = try? container.decode(NotificationRoomResponse.self, forKey: .room)
        sender = (try? container.decode(HostResponse.self, forKey: .sender))
            ?? (try? container.decode(HostResponse.self, forKey: .user))
            ?? (try? container.decode(HostResponse.self, forKey: .actor))
        user = try? container.decode(HostResponse.self, forKey: .user)
        actor = try? container.decode(HostResponse.self, forKey: .actor)
    }
}

struct NotificationRoomResponse: Decodable, Sendable {
    let id: String?
    let title: String?
    let status: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case _id
        case title
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id))
            ?? (try? container.decode(String.self, forKey: ._id))
        title = try? container.decode(String.self, forKey: .title)
        status = try? container.decode(Int.self, forKey: .status)
    }
}

// MARK: - Mapping

enum NotificationMapper {
    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH.mm EEEE"
        return formatter
    }()

    static func map(_ response: NotificationResponse) -> NotificationItem {
        let actor = response.sender
        let username = actor?.username ?? ""
        let fullName = actor?.fullName ?? ""
        let avatar = actor?.profile?.avatar ?? ""

        let resolvedTitle: String
        if let title = response.title, !title.isEmpty {
            resolvedTitle = title
        } else if !username.isEmpty {
            resolvedTitle = "@\(username),"
        } else if !fullName.isEmpty {
            resolvedTitle = fullName
        } else {
            resolvedTitle = "Meydan"
        }

        let resolvedMessage = response.message ?? response.body ?? response.content ?? ""
        let createdDate = parseDate(response.createdAt)
        let resolvedRoomId = response.roomId ?? response.room?.id
        let normalizedType = (response.type ?? "").uppercased()
        let roomStatus = response.room?.status
        let (buttonTitle, buttonStyle) = resolveAction(type: normalizedType, roomStatus: roomStatus)

        return NotificationItem(
            id: response.id,
            imageUrl: avatar.isEmpty ? iconName(for: normalizedType) : avatar,
            title: resolvedTitle,
            message: resolvedMessage,
            time: createdDate.map { displayFormatter.string(from: $0) } ?? "",
            isRead: response.isRead ?? response.read ?? false,
            buttonTitle: buttonTitle,
            buttonStyle: buttonStyle,
            roomId: resolvedRoomId,
            type: response.type,
            createdAt: createdDate
        )
    }

    static func isWithinLastDays(_ date: Date?, days: Int) -> Bool {
        guard let date else { return false }
        guard let threshold = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return false }
        return date >= threshold
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }

        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: value) { return date }

        let withoutFraction = ISO8601DateFormatter()
        withoutFraction.formatOptions = [.withInternetDateTime]
        if let date = withoutFraction.date(from: value) { return date }

        return nil
    }

    private static func iconName(for type: String) -> String {
        switch type {
        case "MENTION", "ROOM_MENTION":
            return "person.crop.square.fill"
        case "ROOM_INVITE", "INVITE":
            return "person.badge.plus"
        case "ROOM_STARTED", "ROOM_LIVE", "STREAM_STARTED":
            return "person.circle.fill"
        case "ROOM_UPDATED", "ROOM_SCHEDULED":
            return "person.crop.circle.fill"
        case "ROOM_ENDED", "STREAM_ENDED":
            return "person.fill"
        default:
            return "person.crop.circle.fill"
        }
    }

    private static func resolveAction(type: String, roomStatus: Int?) -> (String?, NotificationButtonStyle) {
        if type.contains("END") || roomStatus == 2 {
            return ("Sohbet Sona Erdi", .disabled)
        }
        if type.contains("INVITE") || type.contains("START") || type.contains("LIVE") {
            return ("Sohbete Katıl", .active)
        }
        if type.contains("MENTION") {
            return ("Gözat", .active)
        }
        return (nil, .none)
    }
}
