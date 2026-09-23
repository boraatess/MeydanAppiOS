import Foundation

enum SearchDataHelper {
    static func normalizeQuery(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func mapFavorite(_ favorite: FavoriteStreamerResponse) -> FavoriteStreamer {
        let username = favorite.username.map { $0.hasPrefix("@") ? $0 : "@\($0)" } ?? "@unknown"
        let isLive = favorite.isLive ?? favorite.liveRoom.map { $0.status == 1 } ?? false
        let liveTitle = [favorite.liveRoom?.title, favorite.broadcastTitle]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }

        return FavoriteStreamer(
            id: favorite.id,
            isLive: isLive,
            liveRoomId: favorite.liveRoom?.id,
            title: liveTitle,
            name: favorite.fullName ?? favorite.username ?? "Kullanıcı",
            username: username,
            imageName: favorite.profile?.avatar ?? favorite.avatar ?? ""
        )
    }

    static func mapRoom(_ apiRoom: RoomResponse) -> Room {
        let viewersCount = apiRoom.details?.compactMap { $0.finalViewersCount }.max() ?? 0
        let isLive = apiRoom.status == 1

        let creatorName: String
        if !apiRoom.host.username.isEmpty {
            creatorName = "@" + apiRoom.host.username
        } else if !apiRoom.host.fullName.isEmpty {
            creatorName = apiRoom.host.fullName
        } else {
            creatorName = "unknown"
        }

        let creatorImageName: String
        if let avatar = apiRoom.host.profile?.avatar, !avatar.isEmpty {
            creatorImageName = avatar
        } else {
            creatorImageName = "person.crop.circle.fill"
        }

        let imageUrl = apiRoom.image?.isEmpty == false ? apiRoom.image! : "photo.artframe"

        var scheduledDate: Date? = nil
        var scheduledText = ""
        if !isLive, let dateString = apiRoom.date {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                scheduledDate = date
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "tr_TR")
                formatter.dateFormat = "dd.MM.yy HH:mm"
                scheduledText = formatter.string(from: date)
            }
        }

        return Room(
            roomId: apiRoom._id,
            creatorUserId: apiRoom.host._id,
            title: apiRoom.title,
            imageUrl: imageUrl,
            viewersCount: viewersCount,
            creatorName: creatorName,
            creatorUsername: apiRoom.host.username,
            creatorFullName: apiRoom.host.fullName,
            creatorImageName: creatorImageName,
            isLive: isLive,
            scheduledDate: scheduledDate,
            scheduledText: scheduledText,
            categoryId: apiRoom.category?._id,
            categoryName: apiRoom.category?.name
        )
    }

    static func discoverPostsToRooms(_ posts: [DiscoverPost]) -> [Room] {
        posts.map { post in
            Room(
                roomId: post.roomId,
                creatorUserId: post.creatorUserId,
                title: post.title,
                imageUrl: post.roomImage.isEmpty ? post.imageName : post.roomImage,
                viewersCount: post.viewersCount,
                creatorName: post.creatorUsername,
                creatorUsername: post.creatorUsername,
                creatorFullName: post.creatorName,
                creatorImageName: post.creatorImageName,
                isLive: true,
                scheduledDate: nil,
                scheduledText: nil,
                categoryId: post.categoryId,
                categoryName: post.categoryName
            )
        }
    }
}
