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
    func updateRoom(id: String, request: UpdateRoomRequest) async throws -> UpdateRoomResponse
    func deleteRoom(id: String) async throws -> RoomActionResponse
    func startRoom(id: String) async throws -> RoomStatusResponse
    func checkRoomAccess(id: String) async throws -> RoomAccessResponse
    func endRoom(id: String) async throws -> EndRoomResponse
    func scheduleRoomClosure(id: String) async throws -> RoomActionResponse
    func joinRoomViewers(id: String) async throws -> RoomActionResponse
    func leaveRoomViewers(id: String) async throws -> RoomActionResponse
    func fetchRooms() async throws -> RoomsResponse
    func fetchHomeRooms() async throws -> [Room]
    func fetchRooms(forUserId userId: String) async throws -> UserRoomsResponse
    func fetchRoom(id: String) async throws -> RoomResponse
    func inviteUser(request: RoomInviteRequest) async throws -> RoomActionResponse
    func banUser(request: BanRoomUserRequest) async throws -> RoomActionResponse
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

    func updateRoom(id: String, request: UpdateRoomRequest) async throws -> UpdateRoomResponse {
        let url = "\(baseURL)/rooms/\(id)"
        return try await performRequest(url: url, method: .put, parameters: request)
    }

    func deleteRoom(id: String) async throws -> RoomActionResponse {
        let url = "\(baseURL)/room/\(id)"
        return try await performRequest(url: url, method: .delete, parameters: Optional<EmptyParameters>.none)
    }

    func startRoom(id: String) async throws -> RoomStatusResponse {
        let url = "\(baseURL)/rooms/start/\(id)"
        return try await performRequest(url: url, method: .patch, parameters: Optional<EmptyParameters>.none)
    }

    func checkRoomAccess(id: String) async throws -> RoomAccessResponse {
        let url = "\(baseURL)/rooms/\(id)/check-access"
        return try await performRequest(url: url, method: .get, parameters: Optional<EmptyParameters>.none)
    }

    func endRoom(id: String) async throws -> EndRoomResponse {
        let url = "\(baseURL)/rooms/end/\(id)"
        return try await performRequest(url: url, method: .patch, parameters: Optional<EmptyParameters>.none)
    }

    func scheduleRoomClosure(id: String) async throws -> RoomActionResponse {
        let url = "\(baseURL)/room/endRoom"
        let request = EndRoomRequest(roomId: id, immediate: false)
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    func joinRoomViewers(id: String) async throws -> RoomActionResponse {
        let url = "\(baseURL)/rooms/join-room-viewers"
        let request = RoomViewersMutationRequest(roomId: id)
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    func leaveRoomViewers(id: String) async throws -> RoomActionResponse {
        let url = "\(baseURL)/rooms/leave-room-viewers"
        let request = RoomViewersMutationRequest(roomId: id)
        return try await performRequest(url: url, method: .post, parameters: request)
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

    func banUser(request: BanRoomUserRequest) async throws -> RoomActionResponse {
        let url = "\(baseURL)/rooms/ban-user"
        return try await performRequest(url: url, method: .post, parameters: request)
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
            creatorUsername: apiRoom.host.username,
            creatorFullName: apiRoom.host.fullName,
            creatorImageName: creatorImageName,
            isLive: isLive,
            scheduledDate: scheduledDate,
            scheduledText: scheduledText,
            categoryId: apiRoom.category?._id,
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
            if let parameters,
               let bodyData = try? JSONEncoder().encode(parameters),
               let bodyString = String(data: bodyData, encoding: .utf8) {
                print("DEBUG: Request Body: \(bodyString)")
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
                            // Action endpoints may acknowledge success with HTTP 204 and no JSON body.
                            let responseData = data.isEmpty && response.response?.statusCode == 204
                                ? Data("{}".utf8) : data
                            let decoded = try JSONDecoder().decode(T.self, from: responseData)
                            continuation.resume(returning: decoded)
                        } catch {
                            print("ERROR: Decoding error for \(T.self): \(error)")
                            continuation.resume(throwing: NetworkError.serverError(message: "Sunucu yanıtı çözümlenemedi."))
                        }
                    case .failure(let afError):
                        continuation.resume(throwing: Self.mapError(data: response.data, statusCode: response.response?.statusCode, fallback: afError.localizedDescription))
                    }
                }
        }
    }

    nonisolated private static func mapError(data: Data?, statusCode: Int?, fallback: String) -> Error {
        let fallback = RoomHTTPErrorMessage.message(statusCode: statusCode, networkFallback: fallback)
        guard let data else {
            return NetworkError.serverError(message: fallback)
        }

        if let arrayError = try? JSONDecoder().decode(ErrorArrayResponse.self, from: data),
           let first = arrayError.errors.first,
           !first.isEmpty {
            return NetworkError.serverError(message: first)
        }

        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            let message = [errorResponse.message, errorResponse.error]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty }
            return NetworkError.serverError(message: message ?? fallback)
        }

        return NetworkError.serverError(message: fallback)
    }
}
