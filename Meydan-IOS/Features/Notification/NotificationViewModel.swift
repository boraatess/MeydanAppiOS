import Foundation
import SwiftUI

@MainActor
final class NotificationBadgeManager: ObservableObject {
    static let shared = NotificationBadgeManager()

    @Published private(set) var hasUnreadNotifications = false

    private let notificationService: NotificationServiceProtocol

    private init(notificationService: NotificationServiceProtocol = NotificationService.shared) {
        self.notificationService = notificationService
    }

    func setHasUnread(_ hasUnread: Bool) {
        hasUnreadNotifications = hasUnread
    }

    func refresh() async {
        do {
            let response = try await notificationService.fetchNotifications()
            let items = response.notifications.map(NotificationMapper.map)
            hasUnreadNotifications = items.contains { !$0.isRead }
        } catch {
            print("DEBUG: Bildirim badge durumu alınamadı: \(error.localizedDescription)")
        }
    }
}

@MainActor
final class NotificationViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var actionLoadingNotificationId: String?
    @Published var expiredRoomMessage: String?
    @Published var roomAccessMessage: String?

    private let notificationService: NotificationServiceProtocol
    private let roomService: RoomServiceProtocol
    private var markingReadNotificationIds = Set<String>()

    init(
        notificationService: NotificationServiceProtocol = NotificationService.shared,
        roomService: RoomServiceProtocol = RoomService.shared
    ) {
        self.notificationService = notificationService
        self.roomService = roomService
    }

    var last7DaysNotifications: [NotificationItem] {
        notifications.filter { NotificationMapper.isWithinLastDays($0.createdAt, days: 7) }
    }

    var last30DaysNotifications: [NotificationItem] {
        notifications.filter {
            guard let date = $0.createdAt else { return false }
            let within30 = NotificationMapper.isWithinLastDays(date, days: 30)
            let within7 = NotificationMapper.isWithinLastDays(date, days: 7)
            return within30 && !within7
        }
    }

    var olderNotifications: [NotificationItem] {
        notifications.filter {
            guard let date = $0.createdAt else { return true }
            return !NotificationMapper.isWithinLastDays(date, days: 30)
        }
    }

    func fetchNotifications() {
        Task {
            await loadNotifications()
        }
    }

    func markAsRead(_ notification: NotificationItem) {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        let shouldSync = !notifications[index].isRead
        notifications[index].isRead = true
        NotificationBadgeManager.shared.setHasUnread(notifications.contains { !$0.isRead })

        guard shouldSync, !markingReadNotificationIds.contains(notification.id) else { return }
        markingReadNotificationIds.insert(notification.id)

        Task {
            defer { markingReadNotificationIds.remove(notification.id) }

            do {
                _ = try await notificationService.markAsRead(id: notification.id)
            } catch {
                print("DEBUG: Bildirim okundu bilgisi gönderilemedi. notificationId=\(notification.id), error=\(error.localizedDescription)")
            }
        }
    }

    func markAllAsRead() {
        Task {
            await markAllAsReadOnServer()
        }
    }

    func refreshAndMarkAllAsRead() async {
        await markAllAsReadOnServer()
        await loadNotifications()
    }

    func chatDestination(for notification: NotificationItem) async -> ChatDestination? {
        guard notification.buttonStyle == .active,
              notification.actionKind == .openRoom || notification.actionKind == .browseRoom else { return nil }
        guard let roomId = notification.roomId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !roomId.isEmpty else {
            errorMessage = "Bildirim için oda bilgisi bulunamadı."
            return nil
        }

        actionLoadingNotificationId = notification.id
        defer { actionLoadingNotificationId = nil }

        do {
            print("DEBUG: Notification chatDestination başlıyor. notificationId=\(notification.id), roomId=\(roomId), type=\(notification.type ?? "nil")")
            let room = try await roomService.fetchRoom(id: roomId)
            guard room.status != 2 else {
                expiredRoomMessage = "Bu sohbet odasının süresi dolmuş veya oda sona ermiş."
                return nil
            }

            let resolvedRoomId = room._id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !resolvedRoomId.isEmpty else {
                errorMessage = "Oda bilgisi bulunamadı."
                print("DEBUG: Notification fetchRoom sonucu room._id boş. requestedRoomId=\(roomId)")
                return nil
            }

            let access = try await RoomAccessHelper.validateAccess(
                roomId: resolvedRoomId,
                roomOwnerUserId: room.host._id,
                roomService: roomService
            )
            await showAccessMessageIfNeeded(access?.message)

            print("DEBUG: Notification chatDestination hazırlanıyor. resolvedRoomId=\(resolvedRoomId), title=\(room.title), hostId=\(room.host._id)")
            return ChatDestination(
                roomId: resolvedRoomId,
                roomTitle: room.title,
                roomOwnerUsername: formattedUsername(from: room.host),
                roomOwnerUserId: room.host._id
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func profileDestination(for notification: NotificationItem) -> ProfileNavigation? {
        guard notification.buttonStyle == .active,
              notification.actionKind == .openProfile,
              let userId = notification.actorUserId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !userId.isEmpty else { return nil }

        return .otherProfile(
            userId: userId,
            name: notification.actorName ?? notification.actorUsername ?? "",
            username: notification.actorUsername ?? ""
        )
    }

    private func formattedUsername(from host: HostResponse) -> String {
        if !host.username.isEmpty {
            return host.username.hasPrefix("@") ? host.username : "@\(host.username)"
        }

        if !host.fullName.isEmpty {
            return host.fullName
        }

        return "Meydan"
    }

    private func showAccessMessageIfNeeded(_ message: String?) async {
        guard let message = message?.trimmingCharacters(in: .whitespacesAndNewlines),
              !message.isEmpty else { return }

        roomAccessMessage = message
        try? await Task.sleep(nanoseconds: 700_000_000)
        roomAccessMessage = nil
    }

    private func loadNotifications() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await notificationService.fetchNotifications()
            notifications = response.notifications.map(NotificationMapper.map)
            NotificationBadgeManager.shared.setHasUnread(notifications.contains { !$0.isRead })
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private func markAllAsReadOnServer() async {
        do {
            _ = try await notificationService.markAllAsRead()
            for index in notifications.indices {
                notifications[index].isRead = true
            }
            NotificationBadgeManager.shared.setHasUnread(false)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
