import Foundation

struct Category: Identifiable {
    let id = UUID() // Şimdilik sahte ID
    let name: String
}

struct Story: Identifiable {
    let id = UUID()
    let username: String
    let imageUrl: String // API'dan gelen resim URL'i olacak
}

struct Moderator: Identifiable {
    let id = UUID()
    let name: String
    let imageUrl: String
}

struct Room: Identifiable {
    let id = UUID()
    let title: String
    let imageUrl: String
}
