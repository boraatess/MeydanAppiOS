import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    private struct CachedData {
        let people: [FavoriteStreamer]
        let rooms: [Room]
    }

    @Published private(set) var people: [FavoriteStreamer] = []
    @Published private(set) var rooms: [Room] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let userService: UserServiceProtocol
    private var searchTask: Task<Void, Never>?
    private let cacheTTL: TimeInterval = 120

    init(userService: UserServiceProtocol = UserService.shared) {
        self.userService = userService
    }

    func search(query: String) {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            resetResults()
            return
        }

        let cacheKey = "search.\(SearchDataHelper.normalizeQuery(trimmed))"
        if let cached: CachedData = AppMemoryCache.shared.value(forKey: cacheKey, maxAge: cacheTTL) {
            people = cached.people
            rooms = cached.rooms
            errorMessage = nil
            isLoading = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }

            isLoading = true
            errorMessage = nil

            do {
                let response = try await userService.search(query: trimmed)
                guard !Task.isCancelled else { return }
                people = response.users.map(SearchDataHelper.mapFavorite)
                rooms = response.rooms.map(SearchDataHelper.mapRoom)
                AppMemoryCache.shared.set(CachedData(people: people, rooms: rooms), forKey: cacheKey)
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                people = []
                rooms = []
            }

            isLoading = false
        }
    }

    func reset() {
        searchTask?.cancel()
        resetResults()
    }

    private func resetResults() {
        people = []
        rooms = []
        isLoading = false
        errorMessage = nil
    }
}
