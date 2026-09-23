import Foundation
import Alamofire

@MainActor
protocol NotificationServiceProtocol: Sendable {
    func subscribeFCM(request: FCMSubscribeRequest) async throws -> NotificationActionResponse
    func fetchNotifications() async throws -> NotificationsListResponse
    func markAsRead(id: String) async throws -> NotificationActionResponse
    func markAllAsRead() async throws -> NotificationActionResponse
    func subscribeRoom(request: RoomNotificationRequest) async throws -> NotificationActionResponse
    func unsubscribeRoom(request: RoomNotificationRequest) async throws -> NotificationActionResponse
}

@MainActor
final class NotificationService: NotificationServiceProtocol {
    static let shared = NotificationService()

    private let baseURL = AppConfig.apiBaseURL

    private init() {}

    func subscribeFCM(request: FCMSubscribeRequest) async throws -> NotificationActionResponse {
        let url = "\(baseURL)/user/subscribe"
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    func fetchNotifications() async throws -> NotificationsListResponse {
        let url = "\(baseURL)/user/notifications"
        return try await performRequest(url: url, method: .get, parameters: Optional<EmptyParameters>.none)
    }

    func markAsRead(id: String) async throws -> NotificationActionResponse {
        let url = "\(baseURL)/user/notifications/\(id)/read"
        return try await performRequest(url: url, method: .put, parameters: Optional<EmptyParameters>.none)
    }

    func markAllAsRead() async throws -> NotificationActionResponse {
        let url = "\(baseURL)/user/notifications/read"
        return try await performRequest(url: url, method: .put, parameters: Optional<EmptyParameters>.none)
    }

    func subscribeRoom(request: RoomNotificationRequest) async throws -> NotificationActionResponse {
        let url = "\(baseURL)/user/notification/subscribe-room"
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    func unsubscribeRoom(request: RoomNotificationRequest) async throws -> NotificationActionResponse {
        let url = "\(baseURL)/user/notification/unsubscribe-room"
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    private func buildHeaders() -> HTTPHeaders {
        var headers: HTTPHeaders = ["Content-Type": "application/json"]
        if let token = TokenStorage.shared.token, !token.isEmpty {
            headers.add(name: "Authorization", value: "Bearer \(token)")
        }
        return headers
    }

    private func performRequest<T, P>(
        url: String,
        method: HTTPMethod,
        parameters: P?
    ) async throws -> T where T: Decodable & Sendable, P: Encodable & Sendable {
        try await withCheckedThrowingContinuation { continuation in
            let request: DataRequest
            if method == .get {
                request = AF.request(
                    url,
                    method: .get,
                    parameters: parameters,
                    encoder: URLEncodedFormParameterEncoder.default,
                    headers: buildHeaders()
                )
            } else if let parameters {
                request = AF.request(
                    url,
                    method: method,
                    parameters: parameters,
                    encoder: JSONParameterEncoder.default,
                    headers: buildHeaders()
                )
            } else {
                request = AF.request(url, method: method, headers: buildHeaders())
            }

            print("DEBUG: [\(method.rawValue)] \(url)")
            printRequestDebugInfo(url: url, method: method, parameters: parameters)

            request
                .validate()
                .responseData { response in
                    if let data = response.data, let body = String(data: data, encoding: .utf8) {
                        print("DEBUG: Response Code: \(response.response?.statusCode ?? 0)")
                        print("DEBUG: Response Body: \(body)")
                    }

                    switch response.result {
                    case .success(let data):
                        print("response is : \(data)")
                        
                        do {
                            let decoded = try JSONDecoder().decode(T.self, from: data)
                            continuation.resume(returning: decoded)
                        } catch {
                            print("ERROR: Decoding error for \(T.self): \(error)")
                            continuation.resume(throwing: NetworkError.serverError(message: "Sunucu yanıtı çözümlenemedi."))
                        }
                    case .failure(let afError):
                        continuation.resume(throwing: Self.mapError(data: response.data, fallback: afError.localizedDescription))
                    }
                }
        }
    }

    private func printRequestDebugInfo<P: Encodable>(url: String, method: HTTPMethod, parameters: P?) {
        print("DEBUG: Request URL: \(url)")
        print("DEBUG: Request Method: \(method.rawValue)")
        print("DEBUG: Request Has Authorization Header: \(TokenStorage.shared.token?.isEmpty == false)")

        guard let parameters else {
            print("DEBUG: Request Body: <empty>")
            return
        }

        do {
            let data = try JSONEncoder().encode(parameters)
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            print("DEBUG: Request Body: \(body)")
        } catch {
            print("DEBUG: Request Body Encode Error: \(error.localizedDescription)")
        }
    }

    nonisolated private static func mapError(data: Data?, fallback: String) -> Error {
        guard let data else {
            return NetworkError.serverError(message: fallback)
        }

        if let arrayError = try? JSONDecoder().decode(ErrorArrayResponse.self, from: data),
           let first = arrayError.errors.first,
           !first.isEmpty {
            return NetworkError.serverError(message: first)
        }

        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return NetworkError.serverError(message: errorResponse.message ?? errorResponse.error ?? fallback)
        }

        let raw = String(data: data, encoding: .utf8) ?? fallback
        return NetworkError.serverError(message: raw)
    }
}
