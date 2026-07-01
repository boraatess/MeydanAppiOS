struct AuthSuccessResponse: Codable {
    let token: String
    let user: UserResponse
}

struct UserResponse: Codable {
    let id: String
    let username: String
    let email: String
    let provider: String?
    let status: Int?
    let role: String?
}

// API'dan dönebilecek hata modeli
struct APIErrorResponse: Codable, Error {
    let message: String
    let errors: [String]?
}

// Login isteği için model
struct LoginRequest: Codable {
    let identifier: String
    let password: String
}

// Register isteği için model
struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
}

// Sosyal giriş/kayıt isteği için model
struct SocialRequest: Codable {
    let provider: String
    let providerId: String
    let token: String
    let email: String?
    let username: String?
}
