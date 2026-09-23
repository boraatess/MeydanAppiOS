import Foundation

struct Category: Identifiable {
    let id: String
    let name: String

    init(id: String? = nil, name: String) {
        self.id = id?.isEmpty == false ? id! : name
        self.name = name
    }
}

struct Room: Identifiable {
    let id = UUID()
    let roomId: String       // Backend'den gelen gerçek _id
    let creatorUserId: String
    let title: String
    let imageUrl: String
    let viewersCount: Int
    let creatorName: String
    let creatorUsername: String
    let creatorFullName: String
    let creatorImageName: String
    let isLive: Bool
    let scheduledDate: Date?   // Backend'den parse edilen ham tarih
    let scheduledText: String? // Ekranda gösterilecek okunabilir format
    let categoryId: String?
    let categoryName: String?

    init(
        roomId: String,
        creatorUserId: String = "",
        title: String,
        imageUrl: String,
        viewersCount: Int,
        creatorName: String,
        creatorUsername: String? = nil,
        creatorFullName: String? = nil,
        creatorImageName: String,
        isLive: Bool,
        scheduledDate: Date?,
        scheduledText: String?,
        categoryId: String? = nil,
        categoryName: String?
    ) {
        self.roomId = roomId
        self.creatorUserId = creatorUserId
        self.title = title
        self.imageUrl = imageUrl
        self.viewersCount = viewersCount
        self.creatorName = creatorName
        self.creatorUsername = creatorUsername?.isEmpty == false ? creatorUsername! : creatorName
        self.creatorFullName = creatorFullName?.isEmpty == false ? creatorFullName! : creatorName
        self.creatorImageName = creatorImageName
        self.isLive = isLive
        self.scheduledDate = scheduledDate
        self.scheduledText = scheduledText
        self.categoryId = categoryId
        self.categoryName = categoryName
    }
}
