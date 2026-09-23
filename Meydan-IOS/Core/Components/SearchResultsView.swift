import SwiftUI

struct SearchResultsView: View {
    let searchText: String
    let people: [FavoriteStreamer]
    let rooms: [Room]
    @Binding var selectedFilter: SearchFilterType
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var onPersonProfileTap: (FavoriteStreamer) -> Void = { _ in }
    var onRoomJoinTap: (Room) -> Void = { _ in }
    var onRoomProfileTap: (Room) -> Void = { _ in }
    var horizontalPadding: CGFloat = 20

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                if SearchDataHelper.normalizeQuery(searchText).isEmpty {
                    Text("Aramak istediğin kelimeyi yaz")
                        .font(.manrope(.medium, size: 14))
                        .foregroundColor(.grayLight)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else if let errorMessage {
                    Text(errorMessage)
                        .font(.manrope(.medium, size: 14))
                        .foregroundColor(.grayLight)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else {
                    SearchFilterChipsView(
                        selectedFilter: $selectedFilter,
                        horizontalPadding: 0
                    )

                    switch selectedFilter {
                    case .people:
                        peopleContent
                    case .chats:
                        chatsContent
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom)
        }
    }

    @ViewBuilder
    private var chatsContent: some View {
        if rooms.isEmpty {
            emptyResultsView
        } else {
            VStack(spacing: 12) {
                ForEach(rooms) { room in
                    SearchRoomRow(
                        room: room,
                        onProfileTap: { onRoomProfileTap(room) },
                        onJoinTap: { onRoomJoinTap(room) }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var peopleContent: some View {
        if people.isEmpty {
            emptyResultsView
        } else {
            VStack(spacing: 12) {
                ForEach(people) { person in
                    Button {
                        onPersonProfileTap(person)
                    } label: {
                        SearchPersonRow(person: person)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyResultsView: some View {
        Text("Sonuç bulunamadı")
            .font(.manrope(.medium, size: 14))
            .foregroundColor(.grayLight)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)
    }
}

private struct SearchRoomRow: View {
    let room: Room
    let onProfileTap: () -> Void
    let onJoinTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                SearchPersonAvatar(source: room.creatorImageName)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .onTapGesture(perform: onProfileTap)

                VStack(alignment: .leading, spacing: 4) {
                    Text(room.title)
                        .font(.manrope(.bold, size: 16))
                        .foregroundColor(room.isLive ? Color.branding : .white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(room.creatorFullName)
                            .font(.manrope(.semiBold, size: 13))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(room.creatorUsername.hasPrefix("@") ? room.creatorUsername : "@\(room.creatorUsername)")
                            .font(.manrope(.medium, size: 12))
                            .foregroundColor(.grayLight)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(room.isLive ? "Canlı" : "Planlandı")
                    .font(.manrope(.bold, size: 11))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(room.isLive ? Color.branding : Color.white.opacity(0.16))
                    .clipShape(Capsule())
            }

            if room.isLive {
                Button(action: onJoinTap) {
                    Text("Sohbete Katıl")
                        .font(.manrope(.bold, size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.branding)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else if let scheduledText = room.scheduledText, !scheduledText.isEmpty {
                Text(scheduledText)
                    .font(.manrope(.medium, size: 13))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color.grayDark)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SearchPersonRow: View {
    let person: FavoriteStreamer

    var body: some View {
        HStack(spacing: 14) {
            SearchPersonAvatar(source: person.imageName)
                .frame(width: 52, height: 52)
                .clipShape(Circle())

            HStack(spacing: 6) {
                Text(person.name)
                    .font(.manrope(.bold, size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(1)

                Text(person.username)
                    .font(.manrope(.medium, size: 13))
                    .foregroundColor(.grayLight)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(Color.grayDark)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SearchPersonAvatar: View {
    let source: String

    var body: some View {
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
        } else if UIImage(named: source) != nil {
            Image(source)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.12))
            Image(systemName: "person.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.grayLight)
        }
    }
}
