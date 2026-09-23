import Foundation
import Alamofire

@MainActor
protocol ReportServiceProtocol: Sendable {
    func sendReport(request: SendReportRequest) async throws -> EmptyResponse
}

@MainActor
final class ReportService: ReportServiceProtocol {
    
    static let shared = ReportService()
    private let baseURL = AppConfig.apiBaseURL

    private init() {}

    func sendReport(request: SendReportRequest) async throws -> EmptyResponse {
        let url = "\(baseURL)/report/send"
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
            if let parameters,
               let bodyData = try? JSONEncoder().encode(parameters),
               let body = String(data: bodyData, encoding: .utf8) {
                print("DEBUG: Request Body: \(body)")
            }

            request
                .validate()
                .responseData { response in
                    if let data = response.data, let body = String(data: data, encoding: .utf8) {
                        print("DEBUG: Response Code: \(response.response?.statusCode ?? 0)")
                        print("DEBUG: Response Body: \(body)")
                    }

                    switch response.result {
                    case .success(let data):
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
