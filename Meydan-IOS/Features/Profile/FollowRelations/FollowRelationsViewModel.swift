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

    private static func mapUser(_ user: FavoriteStreamerResponse) -> FollowUser {
        let username = user.username ?? "unknown"
        return FollowUser(
            id: user.id,
            name: user.fullName ?? username,
            username: username.hasPrefix("@") ? username : "@\(username)",
            profileImageURL: user.profile?.avatar
        )
    }
}
