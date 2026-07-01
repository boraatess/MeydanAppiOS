//
//  BlockedUser.swift
//  Meydan-IOS
//
//  Created by bora ateş on 24.04.2026.
//

import Foundation

struct BlockedUser: Decodable, Identifiable, Equatable, Sendable {
    let id: String
    let fullName: String
    let username: String?
    let profile: ProfileResponse?
    
    var avatar: String? {
        profile?.avatar
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case fullName = "fullName"
        case username = "username"
        case profile = "profile"
    }
}

struct BlockedUsersResponse: Decodable, Sendable {
    let status: String?
    let blockedUsers: [BlockedUser]
}
