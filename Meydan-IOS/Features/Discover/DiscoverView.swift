import SwiftUI
import Combine
import UIKit

// PreferenceKey to collect frames of each item
fileprivate struct ItemFramePreferenceKey: @preconcurrency PreferenceKey {
    @MainActor static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct DiscoverView: View {
    
    @StateObject private var viewModel: DiscoverViewModel
    
    // Navigation
    @State private var navigationPath = NavigationPath()
    @State private var showFavorites = false
    
    // Popup States
    @State private var showOptions = false
    @State private var showReportSheet = false
    @State private var selectedPost: DiscoverPost? = nil
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var searchFilter: SearchFilterType = .people
    @State private var showChatView = false
    @State private var selectedChatRoom: Room?
    @StateObject private var searchViewModel = SearchViewModel()
    
    // Auto-scroll
    @State private var currentIndex = 0
    // keep a work item-based scheduler instead of Timer to avoid race conditions
    @State private var timerSubscription: Cancellable? = nil
    @State private var autoScrollWorkItem: DispatchWorkItem? = nil
    @State private var isAutoScrolling: Bool = false
    @State private var isUserDragging: Bool = false
    
    // ScrollView'da hedeflenen kartın ID'sini takip eder
    @State private var scrolledID: UUID? = nil
    // frames captured via preferences
    @State private var itemFrames: [UUID: CGRect] = [:]
    // viewport frame in global coordinates
    @State private var viewportFrame: CGRect = .zero
    // ignore preference updates while auto-scrolling
    @State private var ignorePreferenceUpdatesWhileAutoScrolling: Bool = false
    
    // debug flag controlling automatic scrolling; default set from initializer
    @State private var debugDisableAutoScroll: Bool = false
    
    // allow injecting a view model for previews/tests and toggling auto-scroll
    // default startWithAutoScroll = true so auto-paging is enabled unless caller opts out
    init(viewModel: DiscoverViewModel? = nil, startWithAutoScroll: Bool = true) {
        _viewModel = StateObject(wrappedValue: viewModel ?? DiscoverViewModel())
        // debugDisableAutoScroll is true when startWithAutoScroll == false
        _debugDisableAutoScroll = State(initialValue: !startWithAutoScroll)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                
                VStack(spacing: 8) {
                    headerView

                    if isSearchActive {
                        SearchFilterChipsView(selectedFilter: $searchFilter)
                    } else {
                        categoryView
                    }
                }
                .padding(.bottom, 8)

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
                            if let post = viewModel.posts.first(where: { $0.roomId == room.roomId }) {
                                selectedPost = post
                                withAnimation { showOptions = true }
                            }
                        },
                        onRoomJoinTap: { room in
                            selectedChatRoom = room
                            showChatView = true
                        }
                    )
                } else {
                    scrollViewArea
                }
            }
            .padding(.horizontal, 16)
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
            .navigationDestination(for: String.self) { destination in
                if destination == "Favorites" {
                    FavoriteStreamersView()
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showChatView) {
                if let room = selectedChatRoom {
                    ChatView(
                        roomId: room.roomId,
                        roomTitle: room.title,
                        roomOwnerUsername: room.creatorName
                    )
                } else if let post = selectedPost {
                    ChatView(
                        roomId: post.roomId,
                        roomTitle: post.title,
                        roomOwnerUsername: post.creatorUsername
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
                                if let roomId = selectedPost?.roomId {
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
            .overlay {
                if showReportSheet, let post = selectedPost {
                    ZStack {
                        Color.black.opacity(0.55)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    showReportSheet = false
                                }
                            }
                        
                        VStack {
                            ReportView(viewModel: ReportViewModel(context: .stream(roomId: post.roomId, ownerUsername: post.creatorUsername, streamTitle: post.title)), onDismiss: {
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
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let url = viewModel.shareURL {
                    ShareActivityView(items: [url])
                }
            }
        }
        
    }
    
    private var headerView: some View {
        MainHeaderView(
            searchText: $searchText,
            isSearchActive: $isSearchActive,
            onFavoritesTapped: {
                navigationPath.append("Favorites")
            }
        )
    }

    private var categoryView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.categories) { category in
                    Button {
                        withAnimation {
                            if viewModel.selectedCategory?.id == category.id {
                                viewModel.selectedCategory = nil
                            } else {
                                viewModel.selectedCategory = category
                            }
                        }
                    } label: {
                        Text(category.name)
                            .font(.manrope(.medium, size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(viewModel.selectedCategory?.id == category.id ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var scrollViewArea: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    scrollViewContent(geometry: geometry)
                }
                .scrollPositionCompat(id: $scrolledID)
                .scrollDisabled(viewModel.posts.isEmpty)
                .pagingScrollCompat()
            }
        }
    }
    
    private func scrollViewContent(geometry: GeometryProxy) -> some View {
        let availableHeight = geometry.size.height
        let horizontalMargin: CGFloat = 20
        let cardWidth = geometry.size.width - horizontalMargin * 2
        // Kart yüksekliğini biraz daha küçülterek alt ve üstten pay bırakıyoruz
        let cardHeight = availableHeight * 0.88
        
        return LazyVStack(spacing: 0) {
            ForEach(viewModel.posts) { post in
                ZStack {
                    DiscoverCardContent(
                        post: post,
                        onProfileTap: {
                            navigationPath.append(
                                ProfileNavigation.otherProfile(
                                    userId: post.creatorUserId,
                                    name: post.creatorName,
                                    username: post.creatorUsername
                                )
                            )
                        },
                        onJoinTap: {
                            selectedChatRoom = nil
                            selectedPost = post
                            showChatView = true
                        },
                        onOptionsTap: {
                            selectedPost = post
                            withAnimation { showOptions = true }
                        }
                    )
                        .frame(width: cardWidth, height: cardHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                }
                .frame(width: geometry.size.width, height: availableHeight)
                .id(post.id)
            }
        }
    }
}

// Card content: purely the visual content.
struct DiscoverCardContent: View {
    let post: DiscoverPost
    let onProfileTap: () -> Void
    let onJoinTap: () -> Void
    let onOptionsTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background Image (Room Image from API)
            GeometryReader { geo in
                Group {
                    if post.roomImage.starts(with: "http") {
                        AsyncImage(url: URL(string: post.roomImage)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image("sample_match_1")
                                    .resizable()
                                    .scaledToFill()
                            case .empty:
                                Rectangle().fill(Color.white.opacity(0.05))
                                    .overlay(ProgressView().tint(.white))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(post.roomImage.isEmpty ? "sample_match_1" : post.roomImage)
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .contentShape(Rectangle())
                .clipped()
            }
            
            // Gradient Overlays
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.5), .clear, .black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Top Badges
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 16, height: 16)
                    Text("Yayında")
                        .font(.manrope(.bold, size: 14))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.clear)
                .cornerRadius(20)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                    Text("\(post.viewersCount)")
                        .font(.manrope(.bold, size: 12))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
                
                Button(action: onOptionsTap) {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.white)
                        .padding(8)
                }
            }
            .padding(20)
            
            // Bottom Info
            VStack(alignment: .leading, spacing: 12) {
                Spacer()
                
                Button(action: onProfileTap) {
                    HStack(spacing: 12) {
                        // Creator Avatar
                        Group {
                            if post.creatorImageName.starts(with: "http") {
                                AsyncImage(url: URL(string: post.creatorImageName)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 44, height: 44)
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.title)
                                .font(.manrope(.bold, size: 22))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            HStack(spacing: 4) {
                                Text(post.creatorUsername)
                                    .font(.manrope(.medium, size: 14))
                                    .foregroundColor(.white.opacity(0.8))

                                if post.isVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 12))
                                }
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                
                Button(action: onJoinTap) {
                    Text("Sohbete Katıl")
                        .font(.manrope(.bold, size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.branding)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 16)
                
            }
            .padding(8)
            .padding(.bottom, 16)
            
            
        }
    }
}

private struct ScrollPositionCompatModifier<ID: Hashable>: ViewModifier {
    @Binding var id: ID?
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.scrollPosition(id: $id)
        } else {
            content
        }
    }
}

private struct PagingCompatModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.scrollTargetBehavior(.paging)
        } else {
            content
        }
    }
}

private extension View {
    func scrollPositionCompat<ID: Hashable>(id: Binding<ID?>) -> some View {
        self.modifier(ScrollPositionCompatModifier(id: id))
    }
    func pagingScrollCompat() -> some View {
        self.modifier(PagingCompatModifier())
    }
}



struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView(startWithAutoScroll: true)
    }
}
