//
//  UserService.swift
//  Meydan-IOS
//
//  Created by bora ateş on 24.04.2026.
//

import Foundation
import Alamofire

enum FileType: String {
    case avatar = "avatar"
    case room = "room"
    case report = "report"
    case others = "others"
    
}

@MainActor
protocol UserServiceProtocol {
    func getMe() async throws -> MeResponse
    func updateBirthDate(request: UpdateBirthDateRequest) async throws -> Empty
    func updateProfile(request: UpdateProfileRequest) async throws -> Empty
    func uploadProfileImage( imageData: Data, fileName: FileType, mimeType: String, fieldName: String, endpointPath: String ) async throws -> String
    func checkPassword(request: CheckPasswordRequest) async throws -> CheckPasswordResponse
    func setPassword(request: SetPasswordRequest) async throws -> Empty
    func updateEmail(request: UpdateEmailRequest) async throws -> Empty
    func disableAccount(request: DisableAccountRequest) async throws -> Empty
    func getBlockedUsers() async throws -> BlockedUsersResponse
    func unblockUser(with id: String) async throws -> Empty
    func getOtherUser(with id: String) async throws -> OtherUserResponse
    func getUserNetwork(with id: String) async throws -> UserNetworkResponse
    func getMyFavorites() async throws -> FavoriteStreamersResponse
    func addFavoriteUser(with id: String) async throws -> Empty
    func removeFavoriteUser(with id: String) async throws -> Empty
    func userFollow(with id: String) async throws -> Empty
    func userUnfollow(with id: String) async throws -> Empty
    func removeFollower(with id: String) async throws -> Empty
    func blockUser(with id: String) async throws -> Empty
    func fetchUserShareURL(username: String) async throws -> ShareURLResponse
    func search(query: String) async throws -> UserSearchResponse

}

@MainActor
class UserService: UserServiceProtocol {
        
    static let shared = UserService()
    private let baseURL = AppConfig.apiBaseURL
    
    private func buildHeaders() -> HTTPHeaders {
        var headers: HTTPHeaders = ["Content-Type": "application/json"]
        if let token = TokenStorage.shared.token, !token.isEmpty {
            headers.add(name: "Authorization", value: "Bearer \(token)")
        }
        return headers
    }

    private func buildMultipartHeaders() -> HTTPHeaders {
        var headers: HTTPHeaders = [:]
        if let token = TokenStorage.shared.token, !token.isEmpty {
            headers.add(name: "Authorization", value: "Bearer \(token)")
        }
        return headers
    }
  
    func userFollow(with id: String) async throws -> Alamofire.Empty {
        let url = "\(baseURL)/user/follow/\(id)"
        return try await performRequest(url: url, method: .post)
    }
    
    func userUnfollow(with id: String) async throws -> Alamofire.Empty {
        let url = "\(baseURL)/user/unfollow/\(id)"
        return try await performRequest(url: url, method: .post)
    }

    func removeFollower(with id: String) async throws -> Alamofire.Empty {
        let url = "\(baseURL)/user/remove-follower/\(id)"
        return try await performRequest(url: url, method: .post)
    }

    func addFavoriteUser(with id: String) async throws -> Alamofire.Empty {
        let url = "\(baseURL)/user/favorite-streamer/\(id)"
        return try await performRequest(url: url, method: .post)
    }

    func removeFavoriteUser(with id: String) async throws -> Alamofire.Empty {
        let url = "\(baseURL)/user/favorite-streamer/\(id)"
        return try await performRequest(url: url, method: .post)
    }

    func blockUser(with id: String) async throws -> Alamofire.Empty {
        do {
            let url = "\(baseURL)/users/block"
            return try await performRequest(url: url, method: .post, parameters: id)
        } catch {
            let fallbackURL = "\(baseURL)/user/block/\(id)"
            return try await performRequest(url: fallbackURL, method: .post)
        }
    }

    func fetchUserShareURL(username: String) async throws -> ShareURLResponse {
        let url = "\(baseURL)/user/share/\(username)"
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: .get, headers: buildHeaders())
                .validate()
                .responseData { response in
                    print("DEBUG: [GET] \(url)")
                    if let data = response.data, let body = String(data: data, encoding: .utf8) {
                        print("DEBUG: Response Body: \(body)")
                    }
                    switch response.result {
                    case .success(let data):
                        do {
                            let decoded = try JSONDecoder().decode(ShareURLResponse.self, from: data)
                            continuation.resume(returning: decoded)
                        } catch {
                            continuation.resume(throwing: NetworkError.serverError(message: "Yanıt çözümlenemedi."))
                        }
                    case .failure(let afError):
                        continuation.resume(throwing: NetworkError.serverError(message: afError.localizedDescription))
                    }
                }
        }
    }
 
    func getOtherUser(with id: String) async throws -> OtherUserResponse {
        let url = "\(baseURL)/user/profile/\(id)"
        return try await performRequest(url: url, method: .get)
    }

    func getUserNetwork(with id: String) async throws -> UserNetworkResponse {
        let url = "\(baseURL)/user/\(id)/network"
        return try await performRequest(url: url, method: .get)
    }
    
    func getMe() async throws -> MeResponse {
        let url = "\(baseURL)/user/me"
        return try await performRequest(url: url, method: .get)
    }
    
    func getBlockedUsers() async throws -> BlockedUsersResponse {
        let url = "\(baseURL)/user/blocked-list"
        return try await performRequest(url: url, method: .get)
    }

    func getMyFavorites() async throws -> FavoriteStreamersResponse {
        let url = "\(baseURL)/user/my-favorites"
        return try await performRequest(url: url, method: .get)
    }

    func search(query: String) async throws -> UserSearchResponse {
        let url = "\(baseURL)/user/search"
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return try await performQueryRequest(
            url: url,
            parameters: UserSearchQuery(q: trimmed)
        )
    }
    
    func unblockUser(with id: String) async throws -> Empty {
        do {
            let url = "\(baseURL)/users/unblock"
            return try await performRequest(url: url, method: .post, parameters: id)
        } catch {
            let fallbackURL = "\(baseURL)/user/unblock/\(id)"
            return try await performRequest(url: fallbackURL, method: .post)
        }
    }
    
    // MARK: - PROFİLE UPDATE SERVİCES-
    // MARK: - Update Birth Date
    func updateBirthDate(request: UpdateBirthDateRequest) async throws -> Empty {
        let url = "\(baseURL)/user/me"
        return try await performRequest(url: url, method: .put, parameters: request)
    }
    
    func updateProfile(request: UpdateProfileRequest) async throws -> Empty {
        let url = "\(baseURL)/user/me"
        return try await performRequest(url: url, method: .put, parameters: request)
    }

    func uploadProfileImage( imageData: Data, fileName: FileType, mimeType: String = "image/jpeg",
                             fieldName: String = "file", endpointPath: String = "/brand/upload" ) async throws -> String {
        
        let url = "\(baseURL)\(endpointPath)"
        
        let response: ImageUploadResponse = try await withCheckedThrowingContinuation { continuation in
            AF.upload(
                multipartFormData: { multipartFormData in
                    multipartFormData.append(
                        imageData,
                        withName: fieldName,
                        fileName: fileName.rawValue,
                        mimeType: mimeType
                    )
                },
                to: url,
                method: .post,
                headers: buildHeaders()
            )
            .validate()
            .responseDecodable(of: ImageUploadResponse.self) { response in
                print("DEBUG: [POST] \(url)")
                if let data = response.data, let body = String(data: data, encoding: .utf8) {
                    print("DEBUG: Response Code: \(response.response?.statusCode ?? 0)")
                    print("DEBUG: Response Body: \(body)")
                }

                switch response.result {
                case .success(let decoded):
                    continuation.resume(returning: decoded)
                case .failure(let afError):
                    print("ERROR: Upload failed with error: \(afError.localizedDescription)")
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

        guard let uploadedURL = response.uploadedURL, !uploadedURL.isEmpty else {
            throw NetworkError.serverError(message: response.message ?? "Yuklenen gorselin URL bilgisi donmedi.")
        }

        return uploadedURL
    }

    func checkPassword(request: CheckPasswordRequest) async throws -> CheckPasswordResponse {
        let url = "\(baseURL)/user/check-password"
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    func setPassword(request: SetPasswordRequest) async throws -> Empty {
        let url = "\(baseURL)/user/set-password"
        return try await performRequest(url: url, method: .put, parameters: request)
    }

    func updateEmail(request: UpdateEmailRequest) async throws -> Empty {
        let url = "\(baseURL)/user/update-email"
        return try await performRequest(url: url, method: .put, parameters: request)
    }

    func disableAccount(request: DisableAccountRequest) async throws -> Empty {
        let url = "\(baseURL)/user/disable-account"
        return try await performRequest(url: url, method: .put, parameters: request)
    }
    
    
    private func performQueryRequest<T, P>(
        url: String,
        parameters: P
    ) async throws -> T where T: Decodable & Sendable, P: Encodable & Sendable {
        try await withCheckedThrowingContinuation { continuation in
            AF.request(
                url,
                method: .get,
                parameters: parameters,
                encoder: URLEncodedFormParameterEncoder(destination: .queryString),
                headers: buildHeaders()
            )
            .validate()
            .responseData { response in
                print("DEBUG: [GET] \(url)")
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

    // MARK: - Generic Request Helper
    private func performRequest<T, P>(url: String, method: HTTPMethod, parameters: P) async throws -> T
    where T: Decodable & Sendable, P: Encodable & Sendable {
        return try await withCheckedThrowingContinuation { continuation in
            print("DEBUG: [\(method.rawValue)] \(url)")
            if let bodyData = try? JSONEncoder().encode(parameters),
               let body = String(data: bodyData, encoding: .utf8) {
                print("DEBUG: Request Body: \(body)")
            }

            AF.request(url,
                       method: method,
                       parameters: parameters,
                       encoder: JSONParameterEncoder.default,
                       headers: buildHeaders())
            .validate()
            .responseData { response in
                // Detailed Logging
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
                    print("ERROR: Request failed with error: \(afError.localizedDescription)")
                    if let data = response.data {
                        // 1) Önce { "errors": [ ... ] }
                        if let arrayError = try? JSONDecoder().decode(ErrorArrayResponse.self, from: data),
                           let first = arrayError.errors.first, !first.isEmpty {
                            continuation.resume(throwing: NetworkError.serverError(message: first))
                            return
                        }
                        // 2) Sonra { message, error }
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
    
    // Overload for requests without a body (e.g., GET /user/me)
    private func performRequest<T>(url: String, method: HTTPMethod) async throws -> T where T: Decodable & Sendable {
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url,
                       method: method,
                       headers: buildHeaders()) // Authorization header handled globally
            .validate()
            .responseData { response in
                // Detailed Logging
                print("DEBUG: [\(method.rawValue)] \(url)")
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
                    print("ERROR: Request failed with error: \(afError.localizedDescription)")
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
