import Foundation
import SwiftUI

@MainActor
final class NotificationViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let notificationService: NotificationServiceProtocol

    init(notificationService: NotificationServiceProtocol = NotificationService.shared) {
        self.notificationService = notificationService
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
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await notificationService.fetchNotifications()
                notifications = response.notifications.map(NotificationMapper.map)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    func markAsRead(_ notification: NotificationItem) {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        notifications[index].isRead = true
    }

    func markAllAsRead() {
        Task {
            do {
                _ = try await notificationService.markAllAsRead()
                for index in notifications.indices {
                    notifications[index].isRead = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
