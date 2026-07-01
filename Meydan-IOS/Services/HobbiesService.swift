import Foundation
import Alamofire

@MainActor
protocol HobbiesServiceProtocol {
    func setHobbies(request: SetHobbiesRequest, token: String) async throws -> Empty
    func fetchAllHobbies() async throws -> HobbiesResponse
}

struct EmptyParameters: Encodable, Sendable {}

struct SetHobbiesRequest: Encodable, Sendable {
    let hobbies: [String]
}

@MainActor
final class HobbiesService: HobbiesServiceProtocol {
    private let baseURL: String

    init(baseURL: String) {
        self.baseURL = baseURL
    }

    // MARK: - Public API
    func setHobbies(request: SetHobbiesRequest, token: String) async throws -> Empty {
        let url = "\(baseURL)/hobbies/set-hobbies"
        return try await performRequest(url: url, method: .post, parameters: request, token: token)
    }

    func fetchAllHobbies() async throws -> HobbiesResponse {
        let url = "\(baseURL)/hobbies/all"
        return try await performRequest(url: url, method: .get, parameters: Optional<EmptyParameters>.none, token: nil)
    }

    // MARK: - Private Helpers (Alamofire)
    private func performRequest<T, P>(
        url: String,
        method: HTTPMethod,
        parameters: P?,
        token: String?
    ) async throws -> T where T: Decodable & Sendable, P: Encodable & Sendable {
        var headers: HTTPHeaders = ["Content-Type": "application/json"]
        if let token, !token.isEmpty { headers.add(name: "Authorization", value: "Bearer \(token)") }

        return try await withCheckedThrowingContinuation { continuation in
            let request: DataRequest
            if method == .get {
                // GET: never send a body
                request = AF.request(url, method: .get, headers: headers)
            } else if let parameters {
                // Non-GET with body
                request = AF.request(url,
                                     method: method,
                                     parameters: parameters,
                                     encoder: JSONParameterEncoder.default,
                                     headers: headers)
            } else {
                // Non-GET without parameters
                request = AF.request(url, method: method, headers: headers)
            }

            // Detailed Logging
            print("DEBUG: [\(method.rawValue)] \(url)")

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
                        print("ERROR: Request failed: \(afError.localizedDescription)")
                        if let data = response.data {
                            if let arrayError = try? JSONDecoder().decode(ErrorArrayResponse.self, from: data),
                               let first = arrayError.errors.first, !first.isEmpty {
                                continuation.resume(throwing: NetworkError.serverError(message: first))
                                return
                            }
                            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                                let message = errorResponse.message ?? errorResponse.error ?? afError.localizedDescription
                                continuation.resume(throwing: NetworkError.serverError(message: message))
                            } else {
                                let raw = String(data: data, encoding: .utf8) ?? afError.localizedDescription
                                continuation.resume(throwing: NetworkError.serverError(message: raw))
                            }
                        } else {
                            continuation.resume(throwing: NetworkError.serverError(message: afError.localizedDescription))
                        }
                    }
                }
        }
    }
}
