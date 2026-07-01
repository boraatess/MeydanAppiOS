import Foundation

@MainActor
final class OtherUserProfileViewModel: ObservableObject {
    @Published private(set) var userProfile: UserProfile
    @Published private(set) var pastBroadcasts: [PastBroadcast] = []
    @Published private(set) var scheduledBroadcasts: [ScheduledBroadcast] = []
    @Published private(set) var isFollowing = false
    @Published private(set) var isLoading = false
    @Published private(set) var isFollowRequestInProgress = false
    @Published private(set) var errorMessage: String?

    private var userId: String
    private let fallbackUsername: String
    private let userService: UserServiceProtocol
    private let roomService: RoomServiceProtocol

    init(
        userId: String,
        name: String,
        username: String,
        userService: UserServiceProtocol = UserService.shared,
        roomService: RoomServiceProtocol = RoomService.shared
    ) {
        self.userId = userId
        self.fallbackUsername = username
        self.userService = userService
        self.roomService = roomService
        self.userProfile = UserProfile(
            id: userId,
            name: name.isEmpty ? "Kullanıcı" : name,
            username: Self.formattedUsername(username),
            bio: "",
            streamCount: 0,
            followersCount: 0,
            followingCount: 0,
            profileImageURL: "",
            email: ""
        )
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if userId.isEmpty {
                userId = try await resolveUserId(username: fallbackUsername)
            }

            guard !userId.isEmpty else {
                throw NetworkError.serverError(message: "Kullanıcı kimliği bulunamadı.")
            }

            let response = try await userService.getOtherUser(with: userId)
            apply(response.user)
            isFollowing = response.isFollowing ?? false

            let roomsResponse = try await roomService.fetchRooms(forUserId: userId)
            apply(roomsResponse.rooms)

            if response.isFollowing == nil,
               let currentUserResponse = try? await userService.getMe(),
               let currentUserId = currentUserResponse.user.resolvedId {
                isFollowing = response.user.profile?.followers?.contains {
                    $0.id == currentUserId
                } == true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFollow() async {
        guard !userId.isEmpty, !isFollowRequestInProgress else { return }

        isFollowRequestInProgress = true
        errorMessage = nil
        defer { isFollowRequestInProgress = false }

        do {
            if isFollowing {
                _ = try await userService.userUnfollow(with: userId)
            } else {
                _ = try await userService.userFollow(with: userId)
            }

            isFollowing.toggle()
            updateFollowerCount(by: isFollowing ? 1 : -1)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolveUserId(username: String) async throws -> String {
        let normalized = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "@"))

        guard !normalized.isEmpty else { return "" }

        let response = try await userService.search(query: normalized)
        return response.users.first {
            $0.username?.caseInsensitiveCompare(normalized) == .orderedSame
        }?.id ?? response.users.first?.id ?? ""
    }

    private func apply(_ user: MeUser) {
        let resolvedId = user.resolvedId ?? userId
        userId = resolvedId
        userProfile = UserProfile(
            id: resolvedId,
            name: user.fullName ?? userProfile.name,
            username: Self.formattedUsername(user.username ?? userProfile.username),
            bio: user.profile?.bio ?? "Henüz biyografi eklenmemiş.",
            streamCount: userProfile.streamCount,
            followersCount: user.profile?.followers?.count ?? 0,
            followingCount: user.profile?.following?.count ?? 0,
            profileImageURL: user.profile?.avatar ?? "",
            email: user.email ?? ""
        )
    }

    private func apply(_ rooms: [RoomResponse]) {
        scheduledBroadcasts = rooms
            .filter { $0.status == 0 || $0.status == 1 }
            .map {
                ScheduledBroadcast(
                    title: $0.title,
                    date: formattedDate(from: $0.date),
                    time: formattedTime(from: $0.date),
                    imageURL: $0.image?.isEmpty == false ? $0.image! : "onboarding1"
                )
            }

        pastBroadcasts = rooms
            .filter { $0.status != 0 && $0.status != 1 }
            .map {
                PastBroadcast(
                    title: $0.title,
                    date: formattedDate(from: $0.date),
                    duration: "-",
                    imageURL: $0.image?.isEmpty == false ? $0.image! : "onboarding1"
                )
            }

        userProfile = UserProfile(
            id: userProfile.id,
            name: userProfile.name,
            username: userProfile.username,
            bio: userProfile.bio,
            streamCount: rooms.count,
            followersCount: userProfile.followersCount,
            followingCount: userProfile.followingCount,
            profileImageURL: userProfile.profileImageURL,
            email: userProfile.email
        )
    }

    private func updateFollowerCount(by change: Int) {
        userProfile = UserProfile(
            id: userProfile.id,
            name: userProfile.name,
            username: userProfile.username,
            bio: userProfile.bio,
            streamCount: userProfile.streamCount,
            followersCount: max(userProfile.followersCount + change, 0),
            followingCount: userProfile.followingCount,
            profileImageURL: userProfile.profileImageURL,
            email: userProfile.email
        )
    }

    private func parsedDate(from value: String?) -> Date? {
        guard let value else { return nil }
        return Self.fractionalISO8601.date(from: value) ?? Self.iso8601.date(from: value)
    }

    private func formattedDate(from value: String?) -> String {
        parsedDate(from: value).map(Self.dateFormatter.string) ?? "-"
    }

    private func formattedTime(from value: String?) -> String {
        parsedDate(from: value).map(Self.timeFormatter.string) ?? "-"
    }

    private static func formattedUsername(_ value: String) -> String {
        value.hasPrefix("@") ? value : "@\(value)"
    }

    private static let fractionalISO8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601 = ISO8601DateFormatter()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
