enum ReportContext: Equatable {
    case user(userId: String, username: String)
    case stream(roomId: String, ownerUsername: String, streamTitle: String)
}

struct SendReportRequest: Encodable, Sendable {
    let targetType: String
    let targetId: String
    let reason: String
    let description: String
}

enum ReportReasonModel: Identifiable, Equatable {
    case violence
    case harassment
    case spam
    case spoiler
    case hateSpeech
    case inappropriateContent
    case fraud
    case personalData
    case other
    
    var id: String { displayText }
    
    var displayText: String {
        switch self {
        case .violence: return "Şiddet / Tehdit"
        case .harassment: return "Taciz / Zorbalık"
        case .spam: return "Spam"
        case .spoiler: return "Spoiler"
        case .hateSpeech: return "Hakaret / Nefret Söylemi"
        case .inappropriateContent: return "Uygunsuz / Müstehcen İçerik"
        case .fraud: return "Dolandırıcılık / Sahtekarlık"
        case .personalData: return "Kişisel Verilerin Paylaşılması"
        case .other: return "Diğer"
        }
    }
    
    static let streamReasons: [ReportReasonModel] = [
        .violence, .harassment, .spam, .spoiler, .hateSpeech, .inappropriateContent, .fraud, .personalData, .other
    ]
    
    static let userReasons: [ReportReasonModel] = [
        .violence, .harassment, .spam, .spoiler, .hateSpeech, .inappropriateContent, .fraud, .personalData, .other
    ]
}

struct EmptyResponse: Decodable, Sendable {
    // Empty
}


