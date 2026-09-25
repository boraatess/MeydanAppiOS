import Foundation

enum RoomHTTPErrorMessage {
    static func message(statusCode: Int?, networkFallback: String) -> String {
        guard let statusCode else { return networkFallback }
        switch statusCode {
        case 400, 422: return "İşlem gerçekleştirilemedi. Lütfen bilgileri kontrol edip tekrar deneyin."
        case 401: return "Oturumunuz doğrulanamadı. Lütfen tekrar giriş yapın."
        case 403: return "Bu işlemi gerçekleştirme yetkiniz bulunmuyor."
        case 404: return "Yayın bulunamadı. Silinmiş olabilir; lütfen listeyi yenileyin."
        case 408: return "İstek zaman aşımına uğradı. Lütfen tekrar deneyin."
        case 409: return "Yayının durumu bu işlem için uygun değil. Lütfen listeyi yenileyin."
        case 429: return "Çok fazla işlem yaptınız. Lütfen biraz bekleyip tekrar deneyin."
        case 500...599: return "Sunucuda bir sorun oluştu. Lütfen daha sonra tekrar deneyin."
        default: return "İşlem tamamlanamadı. Lütfen tekrar deneyin."
        }
    }
}
