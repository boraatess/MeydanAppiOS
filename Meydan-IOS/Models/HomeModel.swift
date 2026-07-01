import Foundation

struct Category: Identifiable {
    let id = UUID() // temporary mock id
    let name: String
}

struct Room: Identifiable {
    let id = UUID()
    let roomId: String       // Backend'den gelen gerçek _id
    let creatorUserId: String
    let title: String
    let imageUrl: String
    let viewersCount: Int
    let creatorName: String
    let creatorImageName: String
    let isLive: Bool
    let scheduledDate: Date?   // Backend'den parse edilen ham tarih
    let scheduledText: String? // Ekranda gösterilecek okunabilir format
    let categoryName: String?

    init(
        roomId: String,
        creatorUserId: String = "",
        title: String,
        imageUrl: String,
        viewersCount: Int,
        creatorName: String,
        creatorImageName: String,
        isLive: Bool,
        scheduledDate: Date?,
        scheduledText: String?,
        categoryName: String?
    ) {
        self.roomId = roomId
        self.creatorUserId = creatorUserId
        self.title = title
        self.imageUrl = imageUrl
        self.viewersCount = viewersCount
        self.creatorName = creatorName
        self.creatorImageName = creatorImageName
        self.isLive = isLive
        self.scheduledDate = scheduledDate
        self.scheduledText = scheduledText
        self.categoryName = categoryName
    }
}
