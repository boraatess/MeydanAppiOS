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
        isVerified: Bool
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
    }
}

@MainActor
class DiscoverViewModel: ObservableObject {
    
    @Published var posts: [DiscoverPost] = []
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shareURL: URL? = nil
    @Published var showShareSheet = false
    
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
    
    init(roomService: RoomServiceProtocol = RoomService.shared,
         hobbiesService: HobbiesServiceProtocol = HobbiesService(baseURL: AppConfig.apiBaseURL)) {
        self.roomService = roomService
        self.hobbiesService = hobbiesService
        fetchExploreData()
        fetchCategories()
    }
    
    func fetchCategories() {
        Task {
            do {
                let response = try await hobbiesService.fetchAllHobbies()
                self.categories = response.hobbies.map { Category(name: $0.name) }
            } catch {
                print("DEBUG: Categories fetch failed: \(error.localizedDescription)")
                // Fallback mock categories
                self.categories = [
                    .init(name: "diziler"), .init(name: "maç"), 
                    .init(name: "haberler"), .init(name: "magazin")
                ]
            }
        }
    }
    
    func fetchExploreData() {
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
                            isVerified: true
                        )
                    }
                }
                isLoading = false
            } catch {
                print("DEBUG: Explore fetch failed: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                isLoading = false
                fetchMockPosts()
            }
        }
    }
    
    private func fetchMockPosts() {
        self.posts = [
            .init(roomId: "mock_1", imageName: "sample_gaddar", roomImage: "sample_survivor", title: "Ezel", creatorName: "Ay Yapım", creatorUsername: "@ayyapim", creatorImageName: "person.crop.circle.fill", viewersCount: 200, isVerified: true),
            .init(roomId: "mock_2", imageName: "sample_match_1", roomImage: "sample_match_1", title: "Türkiye - İspanya Maçı", creatorName: "Spor Videoları", creatorUsername: "@sporvideolari", creatorImageName: "person.crop.circle.fill", viewersCount: 1271, isVerified: false),
            .init(roomId: "mock_3", imageName: "sample_masterchef", roomImage: "sample_masterchef", title: "Masterchef All Star", creatorName: "Masterchef Türkiye", creatorUsername: "@masterchefturkiye", creatorImageName: "person.crop.circle.fill", viewersCount: 542, isVerified: true),
            .init(roomId: "mock_4", imageName: "sample_survivor", roomImage: "sample_survivor", title: "Survivor All Star", creatorName: "Survivor", creatorUsername: "@survivor", creatorImageName: "person.crop.circle.fill", viewersCount: 14530, isVerified: true),
        ]
    }
}
