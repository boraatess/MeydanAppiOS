import Foundation
import UIKit
import UserNotifications
import FirebaseMessaging

@MainActor
final class PushNotificationManager: ObservableObject {
    static let shared = PushNotificationManager()

    @Published private(set) var fcmToken: String?
    @Published private(set) var subscribedRoomIds: Set<String> = []
    @Published private(set) var permissionGranted = false

    private let notificationService: NotificationServiceProtocol
    private let subscribedRoomsKey = "subscribedRoomNotificationIds"

    private init(notificationService: NotificationServiceProtocol = NotificationService.shared) {
        self.notificationService = notificationService
        loadSubscribedRooms()
    }

    func updateFCMToken(_ token: String?) {
        guard let token, !token.isEmpty, token != fcmToken else { return }
        fcmToken = token
        Task {
            await syncTokenWithBackend()
        }
    }

    func requestPermissionAndRegister() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            permissionGranted = granted
            if granted {
                await UIApplication.shared.registerForRemoteNotifications()
                if let token = try? await Messaging.messaging().token() {
                    updateFCMToken(token)
                }
            }
        } catch {
            print("DEBUG: Bildirim izni alınamadı: \(error.localizedDescription)")
        }
    }

    func syncTokenWithBackend() async {
        guard let token = fcmToken,
              TokenStorage.shared.token != nil else { return }

        do {
            let request = FCMSubscribeRequest(fcmToken: token)
            _ = try await notificationService.subscribeFCM(request: request)
            print("DEBUG: FCM token backend'e kaydedildi.")
        } catch {
            print("DEBUG: FCM token kaydı başarısız: \(error.localizedDescription)")
        }
    }

    func isSubscribedToRoom(_ roomId: String) -> Bool {
        subscribedRoomIds.contains(roomId)
    }

    func subscribeToRoom(roomId: String) async throws {
        let token = try await resolveFCMToken()
        let request = RoomNotificationRequest(fcmToken: token, roomId: roomId)
        _ = try await notificationService.subscribeRoom(request: request)
        subscribedRoomIds.insert(roomId)
        persistSubscribedRooms()
    }

    func unsubscribeFromRoom(roomId: String) async throws {
        let token = try await resolveFCMToken()
        let request = RoomNotificationRequest(fcmToken: token, roomId: roomId)
        _ = try await notificationService.unsubscribeRoom(request: request)
        subscribedRoomIds.remove(roomId)
        persistSubscribedRooms()
    }

    func toggleRoomSubscription(roomId: String) async throws {
        if isSubscribedToRoom(roomId) {
            try await unsubscribeFromRoom(roomId: roomId)
        } else {
            try await subscribeToRoom(roomId: roomId)
        }
    }

    private func resolveFCMToken() async throws -> String {
        if let token = fcmToken, !token.isEmpty {
            return token
        }

        let token = try await Messaging.messaging().token()
        fcmToken = token
        await syncTokenWithBackend()
        return token
    }

    private func loadSubscribedRooms() {
        if let saved = UserDefaults.standard.array(forKey: subscribedRoomsKey) as? [String] {
            subscribedRoomIds = Set(saved)
        }
    }

    private func persistSubscribedRooms() {
        UserDefaults.standard.set(Array(subscribedRoomIds), forKey: subscribedRoomsKey)
    }
}
