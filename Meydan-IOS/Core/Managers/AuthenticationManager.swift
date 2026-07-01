import Foundation
import KeychainAccess

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    
    private let keychain = Keychain(service: "com.meydanapp.token")
    private let tokenKey = "jwt_token"
    
    init() {
        // Uygulama ilk açıldığında Keychain'de kayıtlı bir token var mı diye kontrol
        // Eğer token varsa kullanıcı giriş yapmıştır
        do {
            if let token = try keychain.getString(tokenKey), !token.isEmpty {
                isAuthenticated = true
                // Sync token to TokenStorage so AuthService can attach Authorization header
                TokenStorage.shared.token = token
            }
        } catch {
            // Keychain read error can be ignored at startup
            print("Keychain'den token okunurken hata: \(error)")
        }
    }
    
    /// Başarılı giriş/kayıt sonrası token'ı Keychain'e kaydeder ve durumu günceller.
    func login(token: String) {
        do {
            try keychain.set(token, key: tokenKey)
            TokenStorage.shared.token = token
            self.isAuthenticated = true
            print("Token başarıyla Keychain'e kaydedildi.")
        } catch let error {
            print("Keychain'e kaydederken hata oluştu: \(error)")
        }
    }
    
    /// Token'ı Keychain'den siler ve çıkış yapmış durumuna geçer.
    func logout() {
        do {
            try keychain.remove(tokenKey)
            TokenStorage.shared.clear()
            self.isAuthenticated = false
            print("Token başarıyla Keychain'den silindi.")
        } catch let error {
            print("Keychain'den silerken hata oluştu: \(error)")
        }
    }

    /// Mevcut token'ı Keychain'den okur.
    func currentToken() -> String? {
        return try? keychain.getString(tokenKey)
    }
}

               
