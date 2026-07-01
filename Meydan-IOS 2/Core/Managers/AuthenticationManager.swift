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
        if let _ = try? keychain.getString(tokenKey) {
            isAuthenticated = true
        }
    }
    
    /// Başarılı giriş/kayıt sonrası token'ı Keychain'e kaydeder ve durumu günceller.
    func login(token: String) {
        do {
            try keychain.set(token, key: tokenKey)
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
            self.isAuthenticated = false
            print("Token başarıyla Keychain'den silindi.")
        } catch let error {
            print("Keychain'den silerken hata oluştu: \(error)")
        }
    }
}
