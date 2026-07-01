// Create a lightweight token storage to manage the auth token.
// Uses UserDefaults for simplicity; you can replace with Keychain later.
import Foundation

final class TokenStorage: @unchecked Sendable {
    static let shared = TokenStorage()
    private init() {}

    private let tokenKey = "auth.token"

    var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set {
            if let value = newValue, !value.isEmpty {
                UserDefaults.standard.set(value, forKey: tokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: tokenKey)
            }
        }
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
}
