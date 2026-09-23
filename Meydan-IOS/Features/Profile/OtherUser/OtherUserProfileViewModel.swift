import Foundation

@MainActor
final class OtherUserProfileViewModel: ObservableObject {
    struct CachedData {
        let userProfile: UserProfile
        let pastBroadcasts: [PastBroadcast]
        let scheduledBroadcasts: [ScheduledBroadcast]
        let isFollowing: Bool
        let isFavorite: Bool
        let isBlocked: Bool
    }

    @Published private(set) var userProfile: UserProfile
    @Published private(set) var pastBroadcasts: [PastBroadcast] = []
    @Published private(set) var scheduledBroadcasts: [ScheduledBroadcast] = []
    @Published private(set) var isFollowing = false
    @Published private(set) var isFavorite = false
    @Published private(set) var isBlocked = false
    @Published private(set) var isLoading = false
    @Published private(set) var isProfileReady = false
    @Published private(set) var isFollowRequestInProgress = false
    @Published private(set) var isFavoriteRequestInProgress = false
    @Published private(set) var isBlockingUser = false
    @Published private(set) var errorMessage: String?
    @Published var shareURL: URL?
    @Published var showShareSheet = false

    private var userId: String
    private let fallbackUsername: String
    private let userService: UserServiceProtocol
    private let roomService: RoomServiceProtocol
    private let cacheTTL: TimeInterval = 120

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

    func fetchBroadcasts() {
        // Broadcasts verileri şimdilik mock kalabilir veya başka endpointten çekilebilir
        self.pastBroadcasts = [
            .init(title: "Gündem Değerlendirmesi", date: "28.09.2024", duration: "21:30", imageURL: "onboarding1"),
            .init(title: "Yeni Sezon Analizi", date: "01.10.2024", duration: "22:00", imageURL: "onboarding3")
        ]
        
        self.scheduledBroadcasts = [
            .init(title: "Siyaset Meydanı", date: "24.09.2024", time: "43:12", imageURL: "onboarding1"),
            .init(title: "Teknoloji Sohbetleri", date: "22.09.2024", time: "58:01", imageURL: "onboarding2"),
            .init(title: "Haftalık Gündem", date: "17.09.2024", time: "33:45", imageURL: "onboarding3")
            
        ]
        
    }
    
    
    func load(force: Bool = false) async {
        guard !isLoading else { return }

        if !force,
           let cached: CachedData = AppMemoryCache.shared.value(forKey: cacheKey, maxAge: cacheTTL) {
            apply(cached)
            return
        }

        if force {
            AppMemoryCache.shared.removeValue(forKey: cacheKey)
        }

        isLoading = true
        isProfileReady = false
        errorMessage = nil
        defer { isLoading = false }

        fetchBroadcasts()
        
        
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
            isFavorite = response.isFavorite ?? false
            isBlocked = response.isBlocked ?? false

            if response.isFollowing == nil,
               let currentUserResponse = try? await userService.getMe(),
               let currentUserId = currentUserResponse.user.resolvedId {
                isFollowing = response.user.profile?.followers?.contains {
                    $0.id == currentUserId
                } == true
            }

            isProfileReady = true

            if isBlocked {
                clearBroadcasts()
            } else {
                let roomsResponse = try await roomService.fetchRooms(forUserId: userId)
                apply(roomsResponse.rooms)
            }

            cacheCurrentData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFollow() async {
        guard isProfileReady, !userId.isEmpty, !isBlocked, !isFollowRequestInProgress else { return }

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
            cacheCurrentData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite() async {
        guard !userId.isEmpty, !isFavoriteRequestInProgress else { return }

        isFavoriteRequestInProgress = true
        errorMessage = nil
        defer { isFavoriteRequestInProgress = false }

        do {
            if isFavorite {
                _ = try await userService.removeFavoriteUser(with: userId)
            } else {
                _ = try await userService.addFavoriteUser(with: userId)
            }

            isFavorite.toggle()
            AppMemoryCache.shared.removeValue(forKey: "favorites.streamers")
            cacheCurrentData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchShareURL() {
        let username = userProfile.username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "@"))

        guard !username.isEmpty else { return }

        Task {
            do {
                let response = try await userService.fetchUserShareURL(username: username)
                if let urlString = response.resolvedURL, let url = URL(string: urlString) {
                    shareURL = url
                    showShareSheet = true
                } else if let url = URL(string: "\(AppConfig.apiBaseURL)/user/share/\(username)") {
                    shareURL = url
                    showShareSheet = true
                }
            } catch {
                if let url = URL(string: "\(AppConfig.apiBaseURL)/user/share/\(username)") {
                    shareURL = url
                    showShareSheet = true
                }
            }
        }
    }

    func blockUser() async -> Bool {
        guard !userId.isEmpty, !isBlockingUser else { return false }

        isBlockingUser = true
        errorMessage = nil
        defer { isBlockingUser = false }

        do {
            _ = try await userService.blockUser(with: userId)
            isBlocked = true
            isFollowing = false
            clearBroadcasts()
            AppMemoryCache.shared.removeValue(forKey: "favorites.streamers")
            cacheCurrentData()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func unblockUser() async -> Bool {
        guard !userId.isEmpty, !isBlockingUser else { return false }

        isBlockingUser = true
        errorMessage = nil
        defer { isBlockingUser = false }

        do {
            _ = try await userService.unblockUser(with: userId)
            isBlocked = false
            AppMemoryCache.shared.removeValue(forKey: cacheKey)
            let roomsResponse = try? await roomService.fetchRooms(forUserId: userId)
            if let rooms = roomsResponse?.rooms {
                apply(rooms)
            }
            cacheCurrentData()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func toggleBlock() async -> Bool {
        isBlocked ? await unblockUser() : await blockUser()
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
            .map { room in
                let username = room.host.username.isEmpty ? userProfile.username : room.host.username
                let avatar = room.host.profile?.avatar ?? userProfile.profileImageURL
                return ScheduledBroadcast(
                    id: room._id,
                    title: room.title,
                    date: formattedDate(from: room.date),
                    time: formattedTime(from: room.date),
                    imageURL: room.image?.isEmpty == false ? room.image! : "onboarding1",
                    username: username,
                    profileImageURL: avatar
                )
            }

        pastBroadcasts = rooms
            .filter { $0.status != 0 && $0.status != 1 }
            .map { room in
                PastBroadcast(
                    id: room._id,
                    title: room.title,
                    date: formattedDate(from: room.date),
                    duration: "-",
                    imageURL: room.image?.isEmpty == false ? room.image! : "onboarding1",
                    username: room.host.username.isEmpty ? userProfile.username : room.host.username,
                    profileImageURL: room.host.profile?.avatar ?? userProfile.profileImageURL
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

    private func clearBroadcasts() {
        scheduledBroadcasts = []
        pastBroadcasts = []
        userProfile = UserProfile(
            id: userProfile.id,
            name: userProfile.name,
            username: userProfile.username,
            bio: userProfile.bio,
            streamCount: 0,
            followersCount: userProfile.followersCount,
            followingCount: userProfile.followingCount,
            profileImageURL: userProfile.profileImageURL,
            email: userProfile.email
        )
    }

    private var cacheKey: String {
        "otherUserProfile.\(userId.isEmpty ? fallbackUsername : userId)"
    }

    private func cacheCurrentData() {
        AppMemoryCache.shared.set(
            CachedData(
                userProfile: userProfile,
                pastBroadcasts: pastBroadcasts,
                scheduledBroadcasts: scheduledBroadcasts,
                isFollowing: isFollowing,
                isFavorite: isFavorite,
                isBlocked: isBlocked
            ),
            forKey: cacheKey
        )
    }

    private func apply(_ cached: CachedData) {
        userId = cached.userProfile.id
        isProfileReady = !userId.isEmpty
        userProfile = cached.userProfile
        pastBroadcasts = cached.pastBroadcasts
        scheduledBroadcasts = cached.scheduledBroadcasts
        isFollowing = cached.isFollowing
        isFavorite = cached.isFavorite
        isBlocked = cached.isBlocked
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
