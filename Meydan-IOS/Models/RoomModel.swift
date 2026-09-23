struct RoomsResponse: Decodable, Sendable {
    let status: String
    let results: RoomsResults
}

struct RoomsResults: Decodable, Sendable {
    let followedCount: Int?
    let interestCount: Int?
    let followedRooms: [RoomResponse]
    let interestRooms: [RoomResponse]
}

struct RoomResponse: Decodable, Sendable {
    let _id: String
    let host: HostResponse
    let title: String
    let image: String?
    let category: CategoryResponse?
    let status: Int
    let date: String?
    let details: [RoomDetailResponse]?
    let createdAt: String?
    let updatedAt: String?

    private enum CodingKeys: String, CodingKey {
        case _id
        case id
        case host
        case title
        case name
        case image
        case category
        case status
        case date
        case details
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = (try? container.decode(String.self, forKey: ._id))
            ?? (try? container.decode(String.self, forKey: .id))
            ?? ""
        host = (try? container.decode(HostResponse.self, forKey: .host)) ?? HostResponse.placeholder
        title = (try? container.decode(String.self, forKey: .title))
            ?? (try? container.decode(String.self, forKey: .name))
            ?? ""
        image = try? container.decode(String.self, forKey: .image)
        category = try? container.decode(CategoryResponse.self, forKey: .category)
        status = (try? container.decode(Int.self, forKey: .status)) ?? 0
        date = try? container.decode(String.self, forKey: .date)
        details = try? container.decode([RoomDetailResponse].self, forKey: .details)
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        updatedAt = try? container.decode(String.self, forKey: .updatedAt)
    }
}
/*
  {"status":"OK",
        "results":{
                    "followedCount":0,
                    "interestCount":0,
                    "followedRooms":[],
                    "interestRooms":[]
                }
 
 }

 
 */
struct HostResponse: Decodable, Sendable {
    let _id: String
    let fullName: String
    let username: String
    let profile: ProfileResponse?
    let avatar: String?

    var profileAvatar: String? {
        profile?.avatar ?? avatar
    }

    static let placeholder = HostResponse(_id: "", fullName: "", username: "", profile: nil, avatar: nil)

    private enum CodingKeys: String, CodingKey {
        case _id
        case id
        case fullName
        case username
        case profile
        case avatar
        case image
        case imageUrl
        case profileImage
        case profileImageURL
        case user
        case viewer
        case participant
    }

    init(_id: String, fullName: String, username: String, profile: ProfileResponse?, avatar: String? = nil) {
        self._id = _id
        self.fullName = fullName
        self.username = username
        self.profile = profile
        self.avatar = avatar
    }

    init(from decoder: Decoder) throws {
        if let username = try? decoder.singleValueContainer().decode(String.self) {
            self._id = ""
            self.fullName = ""
            self.username = username
            self.profile = nil
            self.avatar = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nestedUser = (try? container.decode(HostResponse.self, forKey: .user))
            ?? (try? container.decode(HostResponse.self, forKey: .viewer))
            ?? (try? container.decode(HostResponse.self, forKey: .participant))

        _id = (try? container.decode(String.self, forKey: ._id))
            ?? (try? container.decode(String.self, forKey: .id))
            ?? nestedUser?._id
            ?? ""
        fullName = (try? container.decode(String.self, forKey: .fullName))
            ?? nestedUser?.fullName
            ?? ""
        username = (try? container.decode(String.self, forKey: .username))
            ?? nestedUser?.username
            ?? ""
        profile = (try? container.decode(ProfileResponse.self, forKey: .profile))
            ?? nestedUser?.profile
        avatar = (try? container.decode(String.self, forKey: .avatar))
            ?? (try? container.decode(String.self, forKey: .image))
            ?? (try? container.decode(String.self, forKey: .imageUrl))
            ?? (try? container.decode(String.self, forKey: .profileImage))
            ?? (try? container.decode(String.self, forKey: .profileImageURL))
            ?? nestedUser?.avatar
    }
}

struct ProfileResponse: Decodable, Sendable, Equatable {
    let avatar: String?
}

struct CategoryResponse: Decodable, Sendable {
    let _id: String
    let name: String

    private enum CodingKeys: String, CodingKey {
        case _id
        case id
        case name
    }

    init(from decoder: Decoder) throws {
        if let id = try? decoder.singleValueContainer().decode(String.self) {
            self._id = id
            self.name = ""
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = (try? container.decode(String.self, forKey: ._id))
            ?? (try? container.decode(String.self, forKey: .id))
            ?? ""
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
    }
}

struct RoomDetailResponse: Decodable, Sendable {
    let finalViewersCount: Int?
    let startDate: String?
}
