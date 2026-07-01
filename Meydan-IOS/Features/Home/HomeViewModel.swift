import Foundation

// MARK: - ViewModel
@MainActor
class HomeViewModel: ObservableObject {
    // Header
    @Published var searchText: String = ""
    
    // Data Listeleri
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category? = nil
    @Published var filteredRooms: [Room] = []
    @Published var popularRooms: [Room] = []
    
    // Durum Yönetimi
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var shareURL: URL? = nil
    @Published var showShareSheet = false
    @Published var roomNotificationError: String?
    
    func fetchShareURL(roomId: String) {
        Task {
            do {
                let response = try await RoomService.shared.fetchRoomShareURL(id: roomId)
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

    func toggleRoomNotification(roomId: String) {
        roomNotificationError = nil
        Task {
            do {
                try await PushNotificationManager.shared.toggleRoomSubscription(roomId: roomId)
            } catch {
                roomNotificationError = error.localizedDescription
            }
        }
    }
    
    // Rate limiting
    private var lastFetchAt: Date? = nil
    private let minimumRefreshInterval: TimeInterval = 60 // seconds
    
    private let roomService: RoomServiceProtocol = RoomService.shared
    private let hobbiesService: HobbiesServiceProtocol = HobbiesService(baseURL: AppConfig.apiBaseURL)
    
    init() {
                
        Task { @MainActor in
            await fetchHomePageData(force: true)
        }
    }
    
    func fetchHomePageData(force: Bool = false) async {
        // Throttle: avoid frequent refresh within minimumRefreshInterval
        if !force, let last = lastFetchAt, Date().timeIntervalSince(last) < minimumRefreshInterval {
            return
        }
        isLoading = true
        errorMessage = nil

        // Show skeleton placeholders until API response arrives
        self.popularRooms = Self.makeSkeletonRooms(count: 6)

        // Fetch categories from Hobbies API
        do {
            let hobbiesResponse = try await hobbiesService.fetchAllHobbies()
            self.categories = hobbiesResponse.hobbies.map { Category(name: $0.name) }
            
        } catch {
            print("Kategoriler alınırken hata: \(error.localizedDescription)")
        }

        // Fetch rooms from API
        do {
            let apiRooms = try await roomService.fetchHomeRooms()
            self.popularRooms = apiRooms
            self.filteredRooms = apiRooms
            print("API rooms : \(apiRooms)" )
            
            if apiRooms.count == 0 {
                fetchRooms()
                
            }
            
        } catch {
            self.errorMessage = "Veriler yüklenirken bir hata oluştu: \(error.localizedDescription)"
            fetchRooms()
            
        }

        isLoading = false
        lastFetchAt = Date()
        
    }

    // Kullanıcı bir kategoriyi seçtiğinde
    func toggleCategory(_ category: Category) {
        if selectedCategory?.id == category.id {
            selectedCategory = nil
            filteredRooms = popularRooms
        } else {
            selectedCategory = category
            let key = category.name.lowercased()
            filteredRooms = popularRooms.filter { ($0.categoryName ?? "").lowercased() == key }
        }
    }
    
    // Kullanıcı bir odaya katılmak istediğinde
    func joinRoom(room: Room) {
        print("\(room.title) odasına katılma isteği alındı.")
        // TODO: Odaya katılma API isteği
    }
    
    /*             .init(imageName: "sample_gaddar", title: "Gaddar Final Bölümü", creatorName: "@gaddardizi", creatorImageName: "person.crop.circle.fill", viewersCount: 119),
     
     .init(imageName: "sample_match_1", title: "Türkiye - İspanya Maçı", creatorName: "@sporvideolari", creatorImageName: "person.crop.circle.fill", viewersCount: 1271),
    
     .init(imageName: "sample_masterchef", title: "Masterchef All Star", creatorName: "@masterchefturkiye", creatorImageName: "person.crop.circle.fill", viewersCount: 542),
     .init(imageName: "sample_survivor", title: "Survivor All Star", creatorName: "@survivor", creatorImageName: "person.crop.circle.fill", viewersCount: 14530),

     */
    
    func fetchCategories() {
        
        self.categories = [
            
            .init(name: "diziler"),.init(name: "maç"),.init(name: "haberler"), .init(name: "magazin"), .init(name: "aksiyon")
            
        ]
        
    }
    
    func fetchRooms() {
        // API'den veri çekilecekmiş gibi sahte veriler oluşturuyoruz.
        self.filteredRooms = [
            .init(roomId: "mock_1", title: "Gaddar Final Bölümü", imageUrl: "onboarding1", viewersCount: 119, creatorName: "Meydan", creatorImageName: "", isLive: true, scheduledDate: nil, scheduledText: "1 saat sonra", categoryName: "action"),
            .init(roomId: "mock_2", title: "Türkiye - İspanya Maçı", imageUrl: "onboarding2", viewersCount: 1271, creatorName: "Meydan", creatorImageName: "", isLive: false, scheduledDate: nil, scheduledText: "1 saat sonra", categoryName: "action"),
            .init(roomId: "mock_3", title: "Masterchef All Star", imageUrl: "onboarding3", viewersCount: 542, creatorName: "dizikolik", creatorImageName: "", isLive: false, scheduledDate: nil, scheduledText: "1 saat sonra", categoryName: "action"),
            .init(roomId: "mock_4", title: "Survivor All Star", imageUrl: "onboarding1", viewersCount: 2542, creatorName: "Meydan", creatorImageName: "", isLive: true, scheduledDate: nil, scheduledText: "1 saat sonra", categoryName: "action"),
            .init(roomId: "mock_5", title: "Gaddar Final Bölümü", imageUrl: "onboarding1", viewersCount: 119, creatorName: "dizikolik", creatorImageName: "", isLive: true, scheduledDate: nil, scheduledText: "1 saat sonra", categoryName: "action"),
            .init(roomId: "mock_6", title: "Türkiye - İspanya Maçı", imageUrl: "onboarding3", viewersCount: 1271, creatorName: "Meydan", creatorImageName: "", isLive: false, scheduledDate: nil, scheduledText: "1 saat sonra", categoryName: "action"),
            .init(roomId: "mock_7", title: "Masterchef All Star", imageUrl: "onboarding2", viewersCount: 542, creatorName: "AcunMedya", creatorImageName: "", isLive: false, scheduledDate: nil, scheduledText: "1 saat sonra", categoryName: "action"),
            .init(roomId: "mock_8", title: "Survivor All Star", imageUrl: "onboarding1", viewersCount: 2542, creatorName: "AcunMedya", creatorImageName: "", isLive: true, scheduledDate: nil, scheduledText: "1 saat sonra", categoryName: "action")
        ]
        
        self.popularRooms = [
            .init(roomId: "mock_1", title: "Gaddar Final Bölümü", imageUrl: "onboarding1", viewersCount: 119, creatorName: "Meydan", creatorImageName: "", isLive: true, scheduledDate: nil, scheduledText: "1 saat sonra", categoryName: "action"),
            .init(roomId: "mock_2", title: "Türkiye - İspanya Maçı", imageUrl: "onboarding1", viewersCount: 1271, creatorName: "Maçkolik", creatorImageName: "", isLive: false, scheduledDate: nil, scheduledText: "1 saat sonra", categoryName: "action"),
            .init(roomId: "mock_3", title: "Masterchef All Star", imageUrl: "onboarding3", viewersCount: 542, creatorName: "AcunMedya", creatorImageName: "", isLive: false, scheduledDate: nil, scheduledText: "1 saat sonra", categoryName: "action"),
            .init(roomId: "mock_4", title: "Survivor All Star", imageUrl: "onboarding2", viewersCount: 2542, creatorName: "Meydan", creatorImageName: "", isLive: true, scheduledDate: nil, scheduledText: "1 saat sonra", categoryName: "action")
        ]
    }
    
    private static func makeSkeletonRooms(count: Int) -> [Room] {
        guard count > 0 else { return [] }
        return (0..<count).map { _ in
            Room(
                roomId: "",
                title: " ",
                imageUrl: "photo.artframe",
                viewersCount: 0,
                creatorName: " ",
                creatorImageName: "person.crop.circle.fill",
                isLive: false,
                scheduledDate: nil,
                scheduledText: "",
                categoryName: ""
            )
        }
    }
}
