import Foundation

struct HomePageData {
    let categories: [Category]
    let stories: [Story]
    let popularModerators: [Moderator]
    let popularRooms: [Room]
    let followedRooms: [Room]
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
            stories: [
                .init(username: "ahmet", imageUrl: "person.crop.circle.fill"),
                .init(username: "zeynep", imageUrl: "person.crop.circle.fill"),
                .init(username: "can_yilmaz", imageUrl: "person.crop.circle.fill"),
                .init(username: "elif_k", imageUrl: "person.crop.circle.fill"),
                .init(username: "berk", imageUrl: "person.crop.circle.fill"),
                .init(username: "su_deniz", imageUrl: "person.crop.circle.fill"),
                .init(username: "tarkan", imageUrl: "person.crop.circle.fill")
            ],
            popularModerators: [
                .init(name: "Barış Akar", imageUrl: "photo.artframe"),
                .init(name: "Engin Deniz", imageUrl: "photo.artframe"),
                .init(name: "Pelin Çift", imageUrl: "photo.artframe")
            ],
            popularRooms: [
                .init(title: "Gündem Değerlendirmesi: Neler Oluyor?", imageUrl: "photo.artframe"),
                .init(title: "Hisse Senedi Analizi ve Gelecek Beklentileri", imageUrl: "photo.artframe"),
                .init(title: "Haftanın Kritik Maçları ve Yorumlar", imageUrl: "photo.artframe")
            ],
            followedRooms: [
                .init(title: "Yazılımcı Sohbetleri: Swift mi, Kotlin mi?", imageUrl: "photo.artframe"),
                .init(title: "Tarihin Arka Odası: Az Bilinenler", imageUrl: "photo.artframe"),
                .init(title: "Bilim ve Teknoloji: Yapay Zeka Nereye Gidiyor?", imageUrl: "photo.artframe")
            ]
        )
    }
}
