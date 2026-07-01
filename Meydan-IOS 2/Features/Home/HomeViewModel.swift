import Foundation

// MARK: - ViewModel
@MainActor
class HomeViewModel: ObservableObject {
    // Header
    @Published var searchText: String = ""
    
    // Data Listeleri
    @Published var categories: [Category] = []
    @Published var stories: [Story] = []
    @Published var popularModerators: [Moderator] = []
    @Published var popularRooms: [Room] = []
    @Published var followedRooms: [Room] = []
    
    // Durum Yönetimi
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let service: HomeServiceProtocol
    
    init(service: HomeServiceProtocol) {
        self.service = service
        
        Task {
            await fetchHomePageData()
        }
    }
    
    func fetchHomePageData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try await service.fetchAllData()
            
            self.categories = data.categories
            self.stories = data.stories
            self.popularModerators = data.popularModerators
            self.popularRooms = data.popularRooms
            self.followedRooms = data.followedRooms
            
        } catch {
            self.errorMessage = "Veriler yüklenirken bir hata oluştu: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Kullanıcı bir odaya katılmak istediğinde
    func joinRoom(room: Room) {
        print("\(room.title) odasına katılma isteği alındı.")
        // TODO: Odaya katılma API isteği
    }
    
    // Kullanıcı bir moderatörü takip etmek istediğinde
    func followModerator(moderator: Moderator) {
        print("\(moderator.name) takip etme isteği alındı.")
        // TODO: Takip etme API isteği
    }
}
