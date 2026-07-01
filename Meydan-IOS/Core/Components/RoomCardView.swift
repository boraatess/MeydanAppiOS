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
                        HStack(spacing: 6) {
                            Image(systemName: "person")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                            Text("\(room.viewersCount)")
                                .font(.manrope(.bold, size: 12))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .clipShape(Capsule())
                    }

                    Button(action: onOptionsTap) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .bold))
                            .rotationEffect(.degrees(90))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.clear)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                .zIndex(2)

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
                        }
                        .padding(.leading, 8)
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(room.title)
                                .font(.manrope(.bold, size: 20))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(room.creatorName.lowercased())
                                .font(.manrope(.medium, size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 8)
                    }

                    if room.isLive {
                        Text("Sohbete Katıl")
                            .font(.manrope(.bold, size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(red: 1, green: 0.45, blue: 0.4))
                            .cornerRadius(16)
                            .padding(8)
                            .contentShape(Rectangle())
                    } else {
                        HStack(spacing: 12) {
                            HStack {
                                Text(room.scheduledText ?? "")
                                    .font(.manrope(.bold, size: 14))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                            }
                            .background(Color(hex: "1B1B1B"))
                            .cornerRadius(16)

                            Button {
                                onNotificationTap?()
                            } label: {
                                Image(systemName: isNotificationSubscribed ? "bell.fill" : "bell")
                                    .foregroundColor(isNotificationSubscribed ? Color(red: 1, green: 0.45, blue: 0.4) : .white)
                                    .frame(width: 48, height: 48)
                                    .background(Color(hex: "1B1B1B"))
                                    .cornerRadius(16)
                            }
                        }
                        .padding(8)
                    }
                }
                .padding(4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onJoinTap()
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
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
