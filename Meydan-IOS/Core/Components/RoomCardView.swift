import SwiftUI

struct RoomCardView: View {
    let room: Room
    let onProfileTap: () -> Void
    let onOptionsTap: () -> Void
    let onJoinTap: () -> Void
    var isNotificationSubscribed: Bool = false
    var onNotificationTap: (() -> Void)? = nil

    init(
        room: Room,
        onProfileTap: @escaping () -> Void,
        onOptionsTap: @escaping () -> Void,
        onJoinTap: @escaping () -> Void,
        isNotificationSubscribed: Bool = false,
        onNotificationTap: (() -> Void)? = nil
    ) {
        self.room = room
        self.onProfileTap = onProfileTap
        self.onOptionsTap = onOptionsTap
        self.onJoinTap = onJoinTap
        self.isNotificationSubscribed = isNotificationSubscribed
        self.onNotificationTap = onNotificationTap
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                RemoteOrAssetImage(source: room.imageUrl, fallbackSystemImage: "photo")
                    .aspectRatio(1.0, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.1), location: 0),
                                .init(color: .black.opacity(0.4), location: 0.6),
                                .init(color: .black.opacity(0.8), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)

                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(room.isLive ? Color.red : Color.yellow)
                            .frame(width: 16, height: 16)
                        Text(room.isLive ? "Yayında" : "Planlandı")
                            .font(.manrope(.semiBold, size: 14))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.clear)
                    .clipShape(Capsule())

                    Spacer()

                    if room.isLive {
                        LiveViewerCountBadge(
                            roomId: room.roomId,
                            initialCount: room.viewersCount
                        )
                    }

                    Button {
                        print("DEBUG: RoomCard üç nokta tapped. roomId=\(room.roomId), title=\(room.title)")
                        onOptionsTap()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .bold))
                            .rotationEffect(.degrees(90))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.001))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .zIndex(4)
                }
                .padding(8)
                .zIndex(4)

                VStack(alignment: .leading, spacing: 8) {
                    Spacer()

                    HStack(spacing: 0) {
                        Button(action: onProfileTap) {
                            HStack(spacing: 10) {
                                RemoteOrAssetImage(source: room.creatorImageName, fallbackSystemImage: "person.crop.circle.fill")
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            }
                            .frame(width: 52, height: 52)
                            .contentShape(Rectangle())
                        }
                        .padding(.leading, 8)
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(room.title)
                                .font(.manrope(.bold, size: 20))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(displayCreatorUsername)
                                .font(.manrope(.medium, size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 8)
                    }

                    if room.isLive {
                        Button {
                            print("DEBUG: RoomCard Sohbete Katıl tapped. roomId=\(room.roomId), isLive=\(room.isLive), canJoin=\(canJoinRoom), title=\(room.title)")
                            guard canJoinRoom else {
                                print("DEBUG: RoomCard Sohbete Katıl guard engelledi. roomId=\(room.roomId)")
                                return
                            }
                            onJoinTap()
                        } label: {
                            Text("Sohbete Katıl")
                                .font(.manrope(.bold, size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(canJoinRoom ? Color(red: 1, green: 0.45, blue: 0.4) : Color.gray.opacity(0.55))
                                .cornerRadius(16)
                        }
                        .disabled(!canJoinRoom)
                        .buttonStyle(.plain)
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                        .padding(8)
                        .zIndex(5)
                    } else {
                        HStack(spacing: 12) {
                            HStack {
                                Text(room.scheduledText ?? "")
                                    .font(.manrope(.bold, size: 14))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                            }
                            .background(Color(hex: "1B1B1B"))
                            .cornerRadius(16)

                            Button {
                                print("DEBUG: RoomCard bildirim tapped. roomId=\(room.roomId), title=\(room.title), subscribed=\(isNotificationSubscribed)")
                                onNotificationTap?()
                            } label: {
                                Image(systemName: isNotificationSubscribed ? "bell.fill" : "bell")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(isNotificationSubscribed ? Color(red: 1, green: 0.45, blue: 0.4) : .white)
                                    .frame(width: 56, height: 56)
                                    .background(Color(hex: "1B1B1B"))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                        .padding(8)
                    }
                }
                .padding(4)
                .zIndex(6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    private var canJoinRoom: Bool {
        room.isLive && !room.roomId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var displayCreatorUsername: String {
        let username = room.creatorUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else { return "@unknown" }
        return username.hasPrefix("@") ? username.lowercased() : "@\(username.lowercased())"
    }
}

struct RemoteOrAssetImage: View {
    let source: String
    let fallbackSystemImage: String

    var body: some View {
        GeometryReader { geo in
            if let url = URL(string: source), url.scheme != nil {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        placeholder
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            } else if UIImage(named: source) != nil {
                Image(source)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            } else {
                Image(systemName: source.isEmpty ? fallbackSystemImage : source)
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(.white.opacity(0.55))
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.black.opacity(0.25)
            Image(systemName: fallbackSystemImage)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
        }
    }
}
