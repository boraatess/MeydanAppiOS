import Foundation

struct DiscoverPost: Identifiable, Equatable {
    let id = UUID()
    let roomId: String
    let creatorUserId: String
    let imageName: String
    let roomImage: String
    let title: String
    let creatorName: String
    let creatorUsername: String
    let creatorImageName: String
    let viewersCount: Int
    let isVerified: Bool
    let categoryId: String?
    let categoryName: String?

    init(
        roomId: String,
        creatorUserId: String = "",
        imageName: String,
        roomImage: String,
        title: String,
        creatorName: String,
        creatorUsername: String,
        creatorImageName: String,
        viewersCount: Int,
        isVerified: Bool,
        categoryId: String? = nil,
        categoryName: String? = nil
    ) {
        self.roomId = roomId
        self.creatorUserId = creatorUserId
        self.imageName = imageName
        self.roomImage = roomImage
        self.title = title
        self.creatorName = creatorName
        self.creatorUsername = creatorUsername
        self.creatorImageName = creatorImageName
        self.viewersCount = viewersCount
        self.isVerified = isVerified
        self.categoryId = categoryId
        self.categoryName = categoryName
    }
}

@MainActor
class DiscoverViewModel: ObservableObject {
    private struct CachedData {
        let posts: [DiscoverPost]
        let categories: [Category]
    }

    
    @Published var posts: [DiscoverPost] = []
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shareURL: URL? = nil
    @Published var showShareSheet = false

    var filteredPosts: [DiscoverPost] {
        guard let selectedCategory else {
            return posts
        }

        return posts.filter { post in
            postMatchesCategory(post, category: selectedCategory)
        }
    }
    
    func fetchShareURL(roomId: String) {
        Task {
            do {
                let response = try await roomService.fetchRoomShareURL(id: roomId)
                if let urlString = response.resolvedURL, let url = URL(string: urlString) {
                    self.shareURL = url
                    self.showShareSheet = true
                } else {
                    let fallback = AppConfig.apiBaseURL + "/rooms/share/\(roomId)"
                    self.shareURL = URL(string: fallback)
                    self.showShareSheet = true
                }
            } catch {
                print("DEBUG: Share URL alınamadı: \(error.localizedDescription)")
                let fallback = AppConfig.apiBaseURL + "/rooms/share/\(roomId)"
                self.shareURL = URL(string: fallback)
                self.showShareSheet = true
            }
        }
    }
    
    private let roomService: RoomServiceProtocol
    private let hobbiesService: HobbiesServiceProtocol
    private var currentPage = 1
    private let limit = 20
    private let cacheKey = "discover.data"
    private let cacheTTL: TimeInterval = 120
    
    init(roomService: RoomServiceProtocol = RoomService.shared,
         hobbiesService: HobbiesServiceProtocol = HobbiesService(baseURL: AppConfig.apiBaseURL)) {
        self.roomService = roomService
        self.hobbiesService = hobbiesService
        fetchExploreData()
        fetchCategories()
    }
    
    func fetchCategories() {
        Task {
            if let cached: CachedData = AppMemoryCache.shared.value(forKey: cacheKey, maxAge: cacheTTL),
               !cached.categories.isEmpty {
                self.categories = cached.categories
                return
            }

            do {
                let response = try await hobbiesService.fetchAllHobbies()
                self.categories = response.hobbies.map { Category(id: $0._id, name: $0.name) }
                cacheCurrentData()
            } catch {
                print("DEBUG: Categories fetch failed: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchExploreData() {
        if let cached: CachedData = AppMemoryCache.shared.value(forKey: cacheKey, maxAge: cacheTTL),
           !cached.posts.isEmpty {
            posts = cached.posts
            categories = cached.categories
            errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await roomService.fetchExplore(page: currentPage, limit: limit)
                if let feed = response.feed {
                    // trending ve forYou odalarını birleştiriyoruz
                    let apiRooms = feed.trending + feed.forYou
                    
                    self.posts = apiRooms.map { apiRoom in
                        let creatorUsername = !apiRoom.host.username.isEmpty ? "@" + apiRoom.host.username : "@unknown"
                        let creatorAvatar = apiRoom.host.profile?.avatar ?? ""
                        let roomImage = apiRoom.image ?? ""
                        
                        // viewersCount bilgisi bu endpoint'in RoomResponse modelinde 'listeners' olarak yoksa 
                        // varsayılan bir değer veya details'dan max izleyici alınabilir.
                        // Şimdilik 0 veya varsa details'dan alıyoruz.
                        let viewers = apiRoom.details?.compactMap { $0.finalViewersCount }.max() ?? 0
                        
                        return DiscoverPost(
                            roomId: apiRoom._id,
                            creatorUserId: apiRoom.host._id,
                            imageName: "sample_match_1", 
                            roomImage: roomImage,
                            title: apiRoom.title,
                            creatorName: apiRoom.host.fullName,
                            creatorUsername: creatorUsername,
                            creatorImageName: creatorAvatar,
                            viewersCount: viewers,
                            isVerified: true,
                            categoryId: apiRoom.category?._id,
                            categoryName: apiRoom.category?.name
                        )
                    }
                    cacheCurrentData()
                }
                isLoading = false
            } catch {
                print("DEBUG: Explore fetch failed: \(error.localizedDescription)")
                self.posts = []
                self.errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func cacheCurrentData() {
        AppMemoryCache.shared.set(
            CachedData(posts: posts, categories: categories),
            forKey: cacheKey
        )
    }

    private func normalizeCategoryName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private func postMatchesCategory(_ post: DiscoverPost, category: Category) -> Bool {
        if let categoryId = post.categoryId, !categoryId.isEmpty {
            return categoryId == category.id
        }

        return normalizeCategoryName(post.categoryName ?? "") == normalizeCategoryName(category.name)
    }
}
