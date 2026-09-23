import Foundation

struct ChatDestination: Identifiable, Hashable {
    let roomId: String
    let roomTitle: String
    let roomOwnerUsername: String
    let roomOwnerUserId: String

    var id: String { roomId }

    init(
        roomId: String,
        roomTitle: String,
        roomOwnerUsername: String,
        roomOwnerUserId: String
    ) {
        self.roomId = roomId
        self.roomTitle = roomTitle
        self.roomOwnerUsername = roomOwnerUsername
        self.roomOwnerUserId = roomOwnerUserId
    }

    init(room: Room) {
        self.init(
            roomId: room.roomId,
            roomTitle: room.title,
            roomOwnerUsername: room.creatorName,
            roomOwnerUserId: room.creatorUserId
        )
    }

    init(post: DiscoverPost) {
        self.init(
            roomId: post.roomId,
            roomTitle: post.title,
            roomOwnerUsername: post.creatorUsername,
            roomOwnerUserId: post.creatorUserId
        )
    }

    init?(favoriteStreamer: FavoriteStreamer) {
        guard favoriteStreamer.isLive,
              let liveRoomId = favoriteStreamer.liveRoomId,
              !liveRoomId.isEmpty else {
            return nil
        }

        self.init(
            roomId: liveRoomId,
            roomTitle: favoriteStreamer.title ?? "Sohbet Odası",
            roomOwnerUsername: favoriteStreamer.username,
            roomOwnerUserId: favoriteStreamer.id
        )
    }
}
