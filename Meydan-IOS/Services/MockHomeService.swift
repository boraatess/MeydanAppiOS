import Foundation

struct HomePageData {
    let categories: [Category]
    let popularRooms: [Room]
}

@MainActor
protocol HomeServiceProtocol {
    func fetchAllData() async throws -> HomePageData
}

class MockHomeService: HomeServiceProtocol {
    
    func fetchAllData() async throws -> HomePageData {
        // 1 saniyelik sahte bir ağ gecikmesi
        try await Task.sleep(for: .seconds(1))
        
        return HomePageData(
            categories: [
                .init(name: "Futbol"),
                .init(name: "Siyaset"),
                .init(name: "Yatırım"),
                .init(name: "Oyun"),
                .init(name: "Müzik"),
                .init(name: "Teknoloji")
            ],
            popularRooms: [
                .init(roomId: "mock_home_1", title: "Gündem Değerlendirmesi: Neler Oluyor?", imageUrl: "photo.artframe", viewersCount: 200, creatorName: "@gundemci", creatorImageName: "person.crop.circle.fill", isLive: true, scheduledDate: nil, scheduledText: nil, categoryName: "Yerli Dizi"),
                .init(roomId: "mock_home_2", title: "Hisse Senedi Analizi ve Gelecek Beklentileri", imageUrl: "photo.artframe", viewersCount: 120, creatorName: "@yatirimci", creatorImageName: "person.crop.circle.fill", isLive: false, scheduledDate: nil, scheduledText: "14 Ocak 20:00'da başlayacak", categoryName: "Yabancı Dizi"),
                .init(roomId: "mock_home_3", title: "Haftanın Kritik Maçları ve Yorumlar", imageUrl: "photo.artframe", viewersCount: 340, creatorName: "@mackolik", creatorImageName: "person.crop.circle.fill", isLive: true, scheduledDate: nil, scheduledText: nil, categoryName: "Yerli Film")
            ]
        )
    }
}

