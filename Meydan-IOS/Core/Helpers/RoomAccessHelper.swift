import Foundation

@MainActor
enum RoomAccessHelper {
    static func validateAccess(
        roomId: String,
        roomOwnerUserId: String? = nil,
        roomService: RoomServiceProtocol = RoomService.shared
    ) async throws -> RoomAccessResponse? {
        let trimmedRoomId = roomId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRoomId.isEmpty else {
            throw NetworkError.serverError(message: "Oda bilgisi bulunamadı.")
        }

        if let roomOwnerUserId = roomOwnerUserId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !roomOwnerUserId.isEmpty,
           let currentUserId = try? await currentUserId(),
           currentUserId == roomOwnerUserId {
            return nil
        }

        let response = try await roomService.checkRoomAccess(id: trimmedRoomId)
        guard response.isAccessible else {
            throw NetworkError.serverError(message: response.message ?? "Bu sohbet odasına erişim izniniz yok.")
        }

        return response
    }

    private static var cachedCurrentUserId: String?

    private static func currentUserId() async throws -> String {
        if let cachedCurrentUserId, !cachedCurrentUserId.isEmpty {
            return cachedCurrentUserId
        }

        let response = try await AuthService.shared.getMe()
        let userId = response.user.resolvedId ?? ""
        cachedCurrentUserId = userId
        return userId
    }
}
