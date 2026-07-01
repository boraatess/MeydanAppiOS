import SwiftUI

struct SearchResultsView: View {
    let filter: SearchFilterType
    let searchText: String
    let people: [FavoriteStreamer]
    let rooms: [Room]
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var onPersonProfileTap: (FavoriteStreamer) -> Void = { _ in }
    var onRoomProfileTap: (Room) -> Void = { _ in }
    var onRoomOptionsTap: (Room) -> Void = { _ in }
    var onRoomJoinTap: (Room) -> Void = { _ in }

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
                    switch filter {
                    case .people:
                        peopleContent
                    case .chats:
                        chatsContent
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom)
        }
    }

    @ViewBuilder
    private var peopleContent: some View {
        if people.isEmpty {
            emptyResultsView
        } else {
            VStack(spacing: 12) {
                ForEach(people) { person in
                    StreamerCardView(streamer: person)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onPersonProfileTap(person)
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var chatsContent: some View {
        if rooms.isEmpty {
            emptyResultsView
        } else {
            VStack(spacing: 16) {
                ForEach(rooms) { room in
                    RoomCardView(
                        room: room,
                        onProfileTap: { onRoomProfileTap(room) },
                        onOptionsTap: { onRoomOptionsTap(room) },
                        onJoinTap: { onRoomJoinTap(room) }
                    )
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
