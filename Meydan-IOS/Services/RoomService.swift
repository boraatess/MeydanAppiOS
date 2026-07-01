//
//  RoomService.swift
//  Meydan-IOS
//
//  Created by bora ateş on 7.05.2026.
//

import Foundation
import Alamofire

@MainActor
protocol RoomServiceProtocol: Sendable {
    func createRoom(request: CreateRoomRequest) async throws -> CreateRoomResponse
    func startRoom(id: String) async throws -> RoomStatusResponse
    func endRoom(id: String) async throws -> EndRoomResponse
    func fetchRooms() async throws -> RoomsResponse
    func fetchHomeRooms() async throws -> [Room]
    func fetchRooms(forUserId userId: String) async throws -> UserRoomsResponse
    func fetchRoom(id: String) async throws -> RoomResponse
    func inviteUser(request: RoomInviteRequest) async throws -> RoomActionResponse
    func notifyMention(request: RoomMentionNotificationRequest) async throws -> RoomActionResponse
    func fetchExplore(page: Int, limit: Int) async throws -> RoomExploreResponse
    func createPoll(request: CreatePollRequest) async throws -> CreatePollResponse
    func votePoll(request: VotePollRequest) async throws -> VotePollResponse
    func fetchRoomShareURL(id: String) async throws -> ShareURLResponse
    func fetchRoomViewers(id: String) async throws -> RoomViewersResponse
}

@MainActor
final class RoomService: RoomServiceProtocol {
    
    static let shared = RoomService()
    private let baseURL = AppConfig.apiBaseURL
    private let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd.MM.yy HH:mm"
        return formatter
    }()

    private init() {}

    func createRoom(request: CreateRoomRequest) async throws -> CreateRoomResponse {
        let url = "\(baseURL)/rooms/create"
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    func startRoom(id: String) async throws -> RoomStatusResponse {
        let url = "\(baseURL)/rooms/start/\(id)"
        return try await performRequest(url: url, method: .patch, parameters: Optional<EmptyParameters>.none)
    }

    func endRoom(id: String) async throws -> EndRoomResponse {
        let url = "\(baseURL)/rooms/end/\(id)"
        return try await performRequest(url: url, method: .patch, parameters: Optional<EmptyParameters>.none)
    }

    func fetchRooms() async throws -> RoomsResponse {
        let url = "\(baseURL)/rooms"
        return try await performRequest(url: url, method: .get, parameters: Optional<EmptyParameters>.none)
    }

    func fetchHomeRooms() async throws -> [Room] {
        let response = try await fetchRooms()
        let allApiRooms = response.results.followedRooms + response.results.interestRooms

        var uniqueRooms: [RoomResponse] = []
        var seenIds = Set<String>()

        for room in allApiRooms where !seenIds.contains(room._id) {
            uniqueRooms.append(room)
            seenIds.insert(room._id)
        }

        return uniqueRooms.map(makeHomeRoom)
    }

    func fetchRooms(forUserId userId: String) async throws -> UserRoomsResponse {
        let url = "\(baseURL)/rooms/user/\(userId)"
        return try await performRequest(url: url, method: .get, parameters: Optional<EmptyParameters>.none)
    }

    func fetchRoom(id: String) async throws -> RoomResponse {
        let url = "\(baseURL)/rooms/\(id)"
        let response: RoomSingleResponse = try await performRequest(
            url: url,
            method: .get,
            parameters: Optional<EmptyParameters>.none
        )
        return response.room
    }

    func inviteUser(request: RoomInviteRequest) async throws -> RoomActionResponse {
        let url = "\(baseURL)/rooms/invite"
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    func notifyMention(request: RoomMentionNotificationRequest) async throws -> RoomActionResponse {
        let url = "\(baseURL)/rooms/notify-mention"
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    func fetchExplore(page: Int = 1, limit: Int = 20) async throws -> RoomExploreResponse {
        let url = "\(baseURL)/rooms/explore/me"
        let parameters = RoomExploreQuery(page: page, limit: limit)
        return try await performRequest(url: url, method: .get, parameters: parameters)
    }

    func createPoll(request: CreatePollRequest) async throws -> CreatePollResponse {
        let url = "\(baseURL)/rooms/create-poll"
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    func votePoll(request: VotePollRequest) async throws -> VotePollResponse {
        let url = "\(baseURL)/rooms/vote-poll"
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    func fetchRoomShareURL(id: String) async throws -> ShareURLResponse {
        let url = "\(baseURL)/rooms/share/\(id)"
        return try await performRequest(url: url, method: .get, parameters: Optional<EmptyParameters>.none)
    }

    func fetchRoomViewers(id: String) async throws -> RoomViewersResponse {
        let url = "\(baseURL)/rooms/viewers/\(id)"
        return try await performRequest(url: url, method: .get, parameters: Optional<EmptyParameters>.none)
    }

    private func buildHeaders() -> HTTPHeaders {
        var headers: HTTPHeaders = ["Content-Type": "application/json"]
        if let token = TokenStorage.shared.token, !token.isEmpty {
            headers.add(name: "Authorization", value: "Bearer \(token)")
        }
        return headers
    }

    private func makeHomeRoom(from apiRoom: RoomResponse) -> Room {
        let viewersCount = apiRoom.details?.compactMap { $0.finalViewersCount }.max() ?? 0
        let isLive = apiRoom.status == 1

        let creatorName: String
        if !apiRoom.host.username.isEmpty {
            creatorName = "@" + apiRoom.host.username
        } else if !apiRoom.host.fullName.isEmpty {
            creatorName = apiRoom.host.fullName
        } else {
            creatorName = "unknown"
        }

        let creatorImageName: String
        if let avatar = apiRoom.host.profile?.avatar, !avatar.isEmpty {
            creatorImageName = avatar
        } else {
            creatorImageName = "person.crop.circle.fill"
        }

        let imageUrl = apiRoom.image?.isEmpty == false ? apiRoom.image! : "photo.artframe"

        var scheduledDate: Date? = nil
        var scheduledText = ""
        if !isLive, let dateString = apiRoom.date {
            if let date = iso8601Formatter.date(from: dateString) {
                scheduledDate = date
                scheduledText = dateFormatter.string(from: date)
            }
        }

        return Room(
            roomId: apiRoom._id,
            creatorUserId: apiRoom.host._id,
            title: apiRoom.title,
            imageUrl: imageUrl,
            viewersCount: viewersCount,
            creatorName: creatorName,
            creatorImageName: creatorImageName,
            isLive: isLive,
            scheduledDate: scheduledDate,
            scheduledText: scheduledText,
            categoryName: apiRoom.category?.name
        )
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

            print("request url : \(url)")
            
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
