import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var showOptions = false
    @State private var showReportSheet = false
    @State private var selectedRoom: Room? = nil
    @State private var chatDestination: ChatDestination? = nil
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var selectedSearchFilter: SearchFilterType = .people
    @StateObject private var searchViewModel = SearchViewModel()
    @ObservedObject private var pushManager = PushNotificationManager.shared
    @State private var roomAccessError: String?
    @State private var roomAccessMessage: String?

    // Navigation
    @Binding var navigationPath: NavigationPath

    init(navigationPath: Binding<NavigationPath>) {
        self._navigationPath = navigationPath
        _viewModel = StateObject(wrappedValue: HomeViewModel())
    }

    var body: some View {
    
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 8) {
                VStack(spacing: 16) {
                    MainHeaderView(
                        searchText: $searchText,
                        isSearchActive: $isSearchActive,
                        onFavoritesTapped: {
                            navigationPath.append("Favorites")
                        }
                    )

                    if !isSearchActive {
                        CategoryScrollView(
                            categories: viewModel.categories,
                            selectedCategory: $viewModel.selectedCategory,
                            onSelect: viewModel.toggleCategory
                        )
                    }
                }
                .padding(.bottom, 16)

                if isSearchActive {
                    SearchResultsView(
                        searchText: searchText,
                        people: searchViewModel.people,
                        rooms: searchViewModel.rooms,
                        selectedFilter: $selectedSearchFilter,
                        isLoading: searchViewModel.isLoading,
                        errorMessage: searchViewModel.errorMessage,
                        onPersonProfileTap: { person in
                            navigationPath.append(
                                ProfileNavigation.otherProfile(
                                    userId: person.id,
                                    name: person.name,
                                    username: person.username
                                )
                            )
                        },
                        onRoomJoinTap: { room in
                            openChatIfPossible(room)
                        },
                        onRoomProfileTap: { room in
                            navigationPath.append(
                                ProfileNavigation.otherProfile(
                                    userId: room.creatorUserId,
                                    name: room.creatorFullName,
                                    username: room.creatorUsername
                                )
                            )
                        }
                    )
                } else if let errorMessage = viewModel.errorMessage, viewModel.filteredRooms.isEmpty {
                    HomeRoomsErrorView(message: errorMessage) {
                        Task {
                            await viewModel.fetchHomePageData(force: true)
                        }
                    }
                    .padding(.horizontal, 16)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(Array(viewModel.filteredRooms.enumerated()), id: \.element.id) { index, room in
                                    if index == 0 {
                                        AdMobNativeAdCardView(adUnitID: AdMobConfig.homeNativeAdUnitID)
                                            .padding(.horizontal, 20)
                                    }

                                    RoomCardView(room: room, onProfileTap: {
                                        navigationPath.append(
                                            ProfileNavigation.otherProfile(
                                                userId: room.creatorUserId,
                                                name: room.creatorFullName,
                                                username: room.creatorUsername
                                            )
                                        )
                                    }, onOptionsTap: {
                                        print("DEBUG: Home RoomCard options closure çalıştı. roomId=\(room.roomId), title=\(room.title)")
                                        selectedRoom = room
                                        withAnimation { showOptions = true }
                                    }, onJoinTap: {
                                        print("DEBUG: Home RoomCard join closure çalıştı. roomId=\(room.roomId), isLive=\(room.isLive), title=\(room.title)")
                                        openChatIfPossible(room)
                                    }, isNotificationSubscribed: pushManager.isSubscribedToRoom(room.roomId), onNotificationTap: {
                                        print("DEBUG: Home RoomCard notification closure çalıştı. roomId=\(room.roomId), title=\(room.title)")
                                        viewModel.toggleRoomNotification(roomId: room.roomId)
                                    })
                                    .padding(.horizontal, 20)

                                    if (index + 1).isMultiple(of: 5) {
                                        AdMobNativeAdCardView(adUnitID: AdMobConfig.homeNativeAdUnitID)
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                        .padding(.bottom)
                    }
                    .pullToRefresh {
                        await viewModel.fetchHomePageData(force: true)
                    }
                }
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 12)
            .background(Color.background.ignoresSafeArea(edges: .bottom))
            .onChange(of: searchText) { newValue in
                guard isSearchActive else { return }
                searchViewModel.search(query: newValue)
            }
            .onChange(of: isSearchActive) { isActive in
                if isActive {
                    searchViewModel.search(query: searchText)
                } else {
                    searchViewModel.reset()
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .top) {
                if let roomAccessMessage {
                    TransientToastView(message: roomAccessMessage)
                        .padding(.top, 12)
                }
            }
            .alert("Sohbete Katılamıyorsunuz", isPresented: Binding(
                get: { roomAccessError != nil },
                set: { isPresented in
                    if !isPresented {
                        roomAccessError = nil
                    }
                }
            )) {
                Button("Tamam", role: .cancel) { roomAccessError = nil }
            } message: {
                Text(roomAccessError ?? "")
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "Favorites" {
                    FavoriteStreamersView()
                }
            }
            .fullScreenCover(item: $chatDestination) { destination in
                ChatView(
                    roomId: destination.roomId,
                    roomTitle: destination.roomTitle,
                    roomOwnerUsername: destination.roomOwnerUsername,
                    roomOwnerUserId: destination.roomOwnerUserId
                )
            }
            .navigationDestination(for: ProfileNavigation.self) { destination in
                switch destination {
                case .otherProfile(let userId, let name, let username):
                    OtherUserProfileView(userId: userId, name: name, username: username)
                case .followers(let userId):
                    FollowRelationsView(viewModel: FollowRelationsViewModel(type: .followers, userId: userId))
                case .following(let userId):
                    FollowRelationsView(viewModel: FollowRelationsViewModel(type: .following, userId: userId))
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, 12)
            .overlay {
                if showOptions {
                    ZStack {
                        Color.black.opacity(0.58)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation { showOptions = false }
                            }
                        
                        RoomOptionsPopUp(
                            onDismiss: { withAnimation { showOptions = false } },
                            onShare: {
                                withAnimation { showOptions = false }
                                if let roomId = selectedRoom?.roomId {
                                    viewModel.fetchShareURL(roomId: roomId)
                                }
                            },
                            onReport: {
                                withAnimation {
                                    showOptions = false
                                    showReportSheet = true
                                }
                            }
                        )
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                }
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let url = viewModel.shareURL {
                    ShareActivityView(items: [url])
                }
            }
        }
        .overlay {
            if showReportSheet, let room = selectedRoom {
                ZStack {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                showReportSheet = false
                            }
                        }
                    
                    VStack {
                        ReportView(viewModel: ReportViewModel(context: .stream(roomId: room.roomId, ownerUsername: room.creatorName, streamTitle: room.title)), onDismiss: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                showReportSheet = false
                            }
                        })
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 60)
                        
                        Spacer()
                    }
                }
                .zIndex(100)
            }
        }
    }

    private func openChatIfPossible(_ room: Room) {
        let roomId = room.roomId.trimmingCharacters(in: .whitespacesAndNewlines)
        print("DEBUG: Home openChatIfPossible çağrıldı. rawRoomId=\(room.roomId), trimmedRoomId=\(roomId), isLive=\(room.isLive), creatorUserId=\(room.creatorUserId)")
        guard room.isLive, !roomId.isEmpty else {
            print("DEBUG: Sohbete katıl engellendi. isLive=\(room.isLive), roomId=\(room.roomId)")
            return
        }

        Task {
            do {
                let access = try await RoomAccessHelper.validateAccess(
                    roomId: roomId,
                    roomOwnerUserId: room.creatorUserId
                )
                await showAccessMessageIfNeeded(access?.message)
                print("DEBUG: Home chatDestination set ediliyor. roomId=\(roomId), title=\(room.title)")
                chatDestination = ChatDestination(room: room)
            } catch {
                print("DEBUG: Home check-access/chat açma hatası: \(error.localizedDescription)")
                roomAccessError = error.localizedDescription
            }
        }
    }

    private func showAccessMessageIfNeeded(_ message: String?) async {
        guard let message = message?.trimmingCharacters(in: .whitespacesAndNewlines),
              !message.isEmpty else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            roomAccessMessage = message
        }

        try? await Task.sleep(nanoseconds: 700_000_000)

        withAnimation(.easeOut(duration: 0.2)) {
            roomAccessMessage = nil
        }
    }

}

struct HomeView_Preview: PreviewProvider {
    static var previews: some View {
        HomeView(navigationPath: .constant(NavigationPath()))
            .preferredColorScheme(.dark)
    }
}

private struct HomeRoomsErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        Spacer(minLength: 0)

        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundColor(.branding)

            Text(message)
                .font(.manrope(.medium, size: 14))
                .foregroundColor(.grayLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Tekrar Dene", action: onRetry)
                .font(.manrope(.bold, size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity)

        Spacer(minLength: 0)
    }
}
