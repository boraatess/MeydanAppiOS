import Foundation

@MainActor
final class FollowRelationsViewModel: ObservableObject {
    enum RelationType {
        case followers, following
    }

    let type: RelationType
    @Published private(set) var users: [FollowUser] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isPerformingAction = false
    @Published var actionErrorMessage: String?

    private let userId: String
    private let userService: UserServiceProtocol

    init(
        type: RelationType,
        userId: String = "",
        userService: UserServiceProtocol = UserService.shared
    ) {
        self.type = type
        self.userId = userId
        self.userService = userService
    }

    func fetchUsers() async {
        guard !userId.isEmpty else {
            users = []
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let network = try await userService.getUserNetwork(with: userId)
            let source = type == .followers ? network.followers : network.following
            users = source.map(Self.mapUser)
        } catch {
            users = []
            errorMessage = error.localizedDescription
        }
    }

    var title: String {
        switch type {
        case .followers: return "Takipçiler"
        case .following: return "Takip Edilenler"
        }
    }

    func addFavorite(_ user: FollowUser) async {
        await performUserAction {
            _ = try await self.userService.addFavoriteUser(with: user.id)
        }
    }

    func unfollow(_ user: FollowUser) async {
        await performUserAction {
            switch self.type {
            case .followers:
                _ = try await self.userService.removeFollower(with: user.id)
            case .following:
                _ = try await self.userService.userUnfollow(with: user.id)
            }
            self.users.removeAll { $0.id == user.id }
        }
    }

    func block(_ user: FollowUser) async {
        await performUserAction {
            _ = try await self.userService.blockUser(with: user.id)
            self.users.removeAll { $0.id == user.id }
        }
    }

    private func performUserAction(_ action: @escaping () async throws -> Void) async {
        guard !isPerformingAction else { return }

        isPerformingAction = true
        actionErrorMessage = nil
        defer { isPerformingAction = false }

        do {
            try await action()
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    private static func mapUser(_ user: FavoriteStreamerResponse) -> FollowUser {
        let username = user.username ?? "unknown"
        return FollowUser(
            id: user.id,
            name: user.fullName ?? username,
            username: username.hasPrefix("@") ? username : "@\(username)",
            profileImageURL: user.profile?.avatar ?? user.avatar
        )
    }
}
