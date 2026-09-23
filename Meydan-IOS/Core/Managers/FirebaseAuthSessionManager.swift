import Foundation
import FirebaseAuth

@MainActor
enum FirebaseAuthSessionManager {
    static func signInIfNeeded(withCustomToken customToken: String?) async throws {
        guard let customToken = customToken?.trimmingCharacters(in: .whitespacesAndNewlines),
              !customToken.isEmpty else {
            print("DEBUG: Firebase custom token response içinde yok veya boş.")
            return
        }

        let result = try await Auth.auth().signIn(withCustomToken: customToken)
        print("DEBUG: Firebase Auth custom token ile giriş başarılı. uid: \(result.user.uid)")
    }
}
