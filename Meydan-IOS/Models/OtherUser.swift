//
//  OtherUser.swift
//  Meydan-IOS
//
//  Created by bora ateş on 24.04.2026.
//

import Foundation
// MARK: - /user/me Response Models
struct OtherUserResponse: Decodable, Sendable {
    let status: String
    let user: MeUser
    let isFollowing: Bool?
    let isFavorite: Bool?
    let isBlocked: Bool?
    let shareUrl: String?
}

struct OtherUser: Decodable, Sendable {
    let id: String?
    let _id: String?
    let fullName: String?
    let username: String?
    let email: String?
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
    }
}

struct OtherUserProfile: Decodable, Sendable {
    let bio: String?
    let avatar: String?
    let followers: [UserRelationshipReference]?
    let following: [UserRelationshipReference]?
    let hobbies: [String]?
    let birthDate: String?

    enum CodingKeys: String, CodingKey {
        case bio, avatar, followers, following, hobbies
        case birthDate = "birthday"
    }
}
