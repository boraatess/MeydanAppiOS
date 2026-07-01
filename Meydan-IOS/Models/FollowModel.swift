import Foundation

struct FollowUser: Identifiable, Codable {
    let id: String
    let name: String
    let username: String
    let profileImageURL: String?
}

struct UserNetworkResponse: Decodable, Sendable {
    let followers: [FavoriteStreamerResponse]
    let following: [FavoriteStreamerResponse]

    private enum CodingKeys: String, CodingKey {
        case followers
        case following
        case results
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let results = try? container.decode(UserNetworkPayload.self, forKey: .results) {
            followers = results.followers
            following = results.following
        } else if let data = try? container.decode(UserNetworkPayload.self, forKey: .data) {
            followers = data.followers
            following = data.following
        } else {
            followers = (try? container.decode([FavoriteStreamerResponse].self, forKey: .followers)) ?? []
            following = (try? container.decode([FavoriteStreamerResponse].self, forKey: .following)) ?? []
        }
    }
}

private struct UserNetworkPayload: Decodable, Sendable {
    let followers: [FavoriteStreamerResponse]
    let following: [FavoriteStreamerResponse]

    private enum CodingKeys: String, CodingKey {
        case followers
        case following
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        followers = (try? container.decode([FavoriteStreamerResponse].self, forKey: .followers)) ?? []
        following = (try? container.decode([FavoriteStreamerResponse].self, forKey: .following)) ?? []
    }
}
