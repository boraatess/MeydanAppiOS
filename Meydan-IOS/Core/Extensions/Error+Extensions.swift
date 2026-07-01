import Foundation
import Alamofire

extension Error {
    /// Herhangi bir hatayı kendi özel NetworkError tipimize çeviren basit bir yardımcı.
    func toNetworkError() -> NetworkError {
        // Eğer hata zaten bizim özel NetworkError tipimizdeyse, direkt onu döndür.
        if let networkError = self as? NetworkError {
            return networkError
        }
        
        // Diğer tüm hatalar için orijinal hata açıklaması korunacaktır.
        return .unknown(self)
    }
}
