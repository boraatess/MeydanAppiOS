import Foundation

struct AppConfig {
    static var apiBaseURL: String {
        // 1. Config.plist bul
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            fatalError("Config.plist dosyası projede bulunamadı. Core/Config altında olduğundan emin olun.")
        }
        
        // 2. Bu dosyayı bir dictionary olarak oku
        guard let config = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            fatalError("Config.plist dosyası okunamadı veya formatı yanlış.")
        }
        
        // 3. İçindeki "APIBaseURL" değerini al
        guard let url = config["APIBaseURL"] as? String else {
            fatalError("Config.plist içinde APIBaseURL anahtarı bulunamadı veya tipi String değil.")
        }
        
        return url
    }
}
