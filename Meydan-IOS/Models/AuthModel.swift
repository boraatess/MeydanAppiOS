import Foundation

struct RegisterRequest: Codable, Hashable {
    let fullName: String
    let username: String
    let email: String
    let password: String
    var birthday: String?
}

struct RegisterResponse: Codable {
    let status: String?
    let message: String?
    let user: AuthUserMinimal?
    let token: String?
    let error: String?
    let emailVerified: Bool?
}

struct LoginRequest: Codable {
    let identifier: String
    let password: String
}

struct LoginResponse: Decodable {
    let status: String?
    let token: String?
    let user: AuthUserMinimal?
    let message: String?
    let error: String?
    let emailVerified: Bool?

    private enum CodingKeys: String, CodingKey {
        case status
        case token
        case accessToken
        case jwt
        case user
        case message
        case error
        case emailVerified
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nested = try? container.decode(LoginResponsePayload.self, forKey: .data)

        status = (try? container.decode(String.self, forKey: .status)) ?? nested?.status
        token = (try? container.decode(String.self, forKey: .token))
            ?? (try? container.decode(String.self, forKey: .accessToken))
            ?? (try? container.decode(String.self, forKey: .jwt))
            ?? nested?.token
        user = (try? container.decode(AuthUserMinimal.self, forKey: .user)) ?? nested?.user
        message = (try? container.decode(String.self, forKey: .message)) ?? nested?.message
        error = try? container.decode(String.self, forKey: .error)
        emailVerified = (try? container.decode(Bool.self, forKey: .emailVerified))
            ?? nested?.emailVerified
    }
}

private struct LoginResponsePayload: Decodable {
    let status: String?
    let token: String?
    let user: AuthUserMinimal?
    let message: String?
    let emailVerified: Bool?

    private enum CodingKeys: String, CodingKey {
        case status
        case token
        case accessToken
        case jwt
        case user
        case message
        case emailVerified
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try? container.decode(String.self, forKey: .status)
        token = (try? container.decode(String.self, forKey: .token))
            ?? (try? container.decode(String.self, forKey: .accessToken))
            ?? (try? container.decode(String.self, forKey: .jwt))
        user = try? container.decode(AuthUserMinimal.self, forKey: .user)
        message = try? container.decode(String.self, forKey: .message)
        emailVerified = try? container.decode(Bool.self, forKey: .emailVerified)
    }
}

// Minimal user sadece _id içeriyor
struct AuthUserMinimal: Codable {
    let id: String
    enum CodingKeys: String, CodingKey { case id = "_id" }
}

struct SocialLoginRequest: Codable {
    let idToken: String
    let provider: String
    // let birthday: String
}

struct ErrorResponse: Codable {
    let message: String?
    let error: String?
}

struct ErrorArrayResponse: Codable {
    let errors: [String]
}

struct ForgotPasswordRequest: Codable {
    let email: String
}

struct ResetPasswordRequest: Codable {
    let resetToken: String
    let newPassword: String
}
struct VerifyResetCodeRequest: Codable {
    let code: String
}

struct VerifyResetCodeResponse: Codable {
    let status: String?
    let success: Bool?
    let message: String?
    let resetToken: String?
    
    var isSuccess: Bool {
        if let success = success { return success }
        if let status = status { return status.lowercased() == "ok" }
        return false
    }
}

struct UpdateBirthDateRequest: Codable {
    let profile: BirthDateProfile

    struct BirthDateProfile: Codable {
        let birthDate: String
    }
}
struct UpdateProfileRequest: Encodable, Sendable {
    let username: String?
    let fullName: String?
    let bio: String?
    let avatar: String?
    let birthday: String?
}

struct ImageUploadResponse: Decodable, Sendable {
    let status: String?
    let message: String?
    let url: String?
    let imageUrl: String?
    let avatar: String?
    let data: ImageUploadData?

    var uploadedURL: String? {
        url ?? imageUrl ?? avatar ?? data?.url ?? data?.imageUrl ?? data?.avatar
    }
}

struct ImageUploadData: Decodable, Sendable {
    let url: String?
    let imageUrl: String?
    let avatar: String?
}

struct DisableAccountRequest: Encodable, Sendable {
    let password: String
}

struct RequestEmailUpdateRequest: Encodable, Sendable {
    let newEmail: String
}

struct VerifyEmailUpdateRequest: Encodable, Sendable {
    let code: String
    let newEmail: String
}

struct SupportRequest: Encodable, Sendable {
    let subject: String
    let message: String
    let images: [String]
}
