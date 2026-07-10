import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var showOptions = false
    @State private var showReportSheet = false
    @State private var selectedRoom: Room? = nil
    @State private var showChatView = false
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var searchFilter: SearchFilterType = .people
    @StateObject private var searchViewModel = SearchViewModel()
    @ObservedObject private var pushManager = PushNotificationManager.shared

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

                    if isSearchActive {
                        SearchFilterChipsView(selectedFilter: $searchFilter)
                    } else {
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
                        filter: searchFilter,
                        searchText: searchText,
                        people: searchViewModel.people,
                        rooms: searchViewModel.rooms,
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
                        onRoomProfileTap: { room in
                            navigationPath.append(
                                ProfileNavigation.otherProfile(
                                    userId: room.creatorUserId,
                                    name: room.creatorName,
                                    username: room.creatorName
                                )
                            )
                        },
                        onRoomOptionsTap: { room in
                            selectedRoom = room
                            withAnimation { showOptions = true }
                        },
                        onRoomJoinTap: { room in
                            selectedRoom = room
                            showChatView = true
                        }
                    )
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(Array(viewModel.filteredRooms.enumerated()), id: \.element.id) { index, room in
                                    if index == 0 {
                                        AdMobBannerAdView(adUnitID: AdMobConfig.homeBannerAdUnitID)
                                            .padding(.horizontal, 20)
                                    }

                                    RoomCardView(room: room, onProfileTap: {
                                        navigationPath.append(ProfileNavigation.otherProfile(userId: room.creatorUserId, name: room.creatorName, username: room.creatorName))
                                    }, onOptionsTap: {
                                        selectedRoom = room
                                        withAnimation { showOptions = true }
                                    }, onJoinTap: {
                                        print("🚀 SOHBETE KATIL TAPPED!")
                                        selectedRoom = room
                                        showChatView = true
                                    }, isNotificationSubscribed: pushManager.isSubscribedToRoom(room.roomId), onNotificationTap: {
                                        viewModel.toggleRoomNotification(roomId: room.roomId)
                                    })
                                    .padding(.horizontal, 20)

                                    if (index + 1).isMultiple(of: 5) {
                                        AdMobBannerAdView(adUnitID: AdMobConfig.homeBannerAdUnitID)
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                        .padding(.bottom)
                    }
                    .pullToRefresh {
                        await viewModel.fetchHomePageData()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
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
            .navigationDestination(for: String.self) { destination in
                if destination == "Favorites" {
                    FavoriteStreamersView()
                }
            }
            .fullScreenCover(isPresented: $showChatView) {
                if let room = selectedRoom {
                    ChatView(
                        roomId: room.roomId,
                        roomTitle: room.title,
                        roomOwnerUsername: room.creatorName
                    )
                }
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

}

struct HomeView_Preview: PreviewProvider {
    static var previews: some View {
        HomeView(navigationPath: .constant(NavigationPath()))
            .preferredColorScheme(.dark)
    }
}
