import SwiftUI

struct OtherUserProfileView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var pushManager = PushNotificationManager.shared
    @StateObject private var viewModel: OtherUserProfileViewModel
    @State private var showOptions = false
    @State private var showReportSheet = false
    
    let userId: String
    let name: String
    let username: String

    init(userId: String, name: String, username: String) {
        self.userId = userId
        self.name = name
        self.username = username
        _viewModel = StateObject(
            wrappedValue: OtherUserProfileViewModel(
                userId: userId,
                name: name,
                username: username
            )
        )
    }
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
                    }
                    
                    Text("Profil")
                        .font(.manrope(.bold, size: 20))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        withAnimation { showOptions.toggle() }
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.clear))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Profile Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top, spacing: 20) {
                                profileImage
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(viewModel.userProfile.name)
                                        .font(.manrope(.bold, size: 22))
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 20) {
                                        UserStatItem(count: "\(viewModel.userProfile.streamCount)", label: "yayın")
                                        NavigationLink {
                                            FollowRelationsView(
                                                viewModel: FollowRelationsViewModel(
                                                    type: .followers,
                                                    userId: viewModel.userProfile.id
                                                ),
                                                showsUserOptions: false
                                            )
                                        } label: {
                                            UserStatItem(count: "\(viewModel.userProfile.followersCount)", label: "takipçi")
                                        }
                                        NavigationLink {
                                            FollowRelationsView(
                                                viewModel: FollowRelationsViewModel(
                                                    type: .following,
                                                    userId: viewModel.userProfile.id
                                                ),
                                                showsUserOptions: false
                                            )
                                        } label: {
                                            UserStatItem(count: "\(viewModel.userProfile.followingCount)", label: "takip")
                                        }
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.userProfile.username)
                                    .font(.manrope(.bold, size: 16))
                                    .foregroundColor(.white)
                                
                                Text(viewModel.userProfile.bio)
                                    .font(.manrope(.medium, size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(3)
                            }
                            
                            // Follow Button
                            Button {
                                Task {
                                    if viewModel.isBlocked {
                                        _ = await viewModel.unblockUser()
                                    } else {
                                        await viewModel.toggleFollow()
                                    }
                                }
                            } label: {
                                Group {
                                    if viewModel.isFollowRequestInProgress || viewModel.isBlockingUser {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text(followButtonTitle)
                                    }
                                }
                                    .font(.manrope(.bold, size: 16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(viewModel.isFollowing || viewModel.isBlocked ? Color.white.opacity(0.1) : Color.white.opacity(0.15))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                            .disabled(viewModel.isFollowRequestInProgress || viewModel.isBlockingUser || !viewModel.isProfileReady)

                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.manrope(.medium, size: 13))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        VStack(spacing: 12) {
                            Text("Canlı & Planlanan Yayınlar")
                                .font(.manrope(.bold, size: 18))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, 16)

                            profileContent
                        }
                    }
                }
                .pullToRefresh {
                    await viewModel.load(force: true)
                }
            }
            .padding(.horizontal, 16)
            .blur(radius: showOptions ? 2 : 0)
            
            // Options Overlay
            if showOptions {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showOptions = false }
                    }
                
                UserOptionsPopUp(
                    isFollowing: viewModel.isFollowing,
                    isFavorite: viewModel.isFavorite,
                    isBlocked: viewModel.isBlocked,
                    isFavoriteRequestInProgress: viewModel.isFavoriteRequestInProgress,
                    isBlockingUser: viewModel.isBlockingUser,
                    onDismiss: { withAnimation { showOptions = false } },
                    onFavoriteTap: {
                        withAnimation { showOptions = false }
                        Task { await viewModel.toggleFavorite() }
                    },
                    onShareTap: {
                        withAnimation { showOptions = false }
                        viewModel.fetchShareURL()
                    },
                    onFollowTap: {
                        withAnimation { showOptions = false }
                        Task {
                            if viewModel.isBlocked {
                                _ = await viewModel.unblockUser()
                            } else {
                                await viewModel.toggleFollow()
                            }
                        }
                    },
                    onReportTap: {
                        withAnimation { showOptions = false }
                        showReportSheet = true
                    },
                    onBlockTap: {
                        withAnimation { showOptions = false }
                        Task {
                            _ = await viewModel.toggleBlock()
                        }
                    }
                )
                    .transition(.scale(scale: 0.9, anchor: .topTrailing).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.shareURL {
                ShareActivityView(items: [url])
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportView(
                viewModel: ReportViewModel(
                    context: .user(
                        userId: viewModel.userProfile.id,
                        username: viewModel.userProfile.username.trimmingCharacters(in: CharacterSet(charactersIn: "@"))
                    )
                ),
                onDismiss: { showReportSheet = false }
            )
        }
    }

    @ViewBuilder
    private var profileImage: some View {
        if let url = URL(string: viewModel.userProfile.profileImageURL), url.scheme != nil {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    defaultProfileImage
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
        } else {
            defaultProfileImage
        }
    }

    private var defaultProfileImage: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFill()
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
            .foregroundColor(.grayLight)
    }

    @ViewBuilder
    private var profileContent: some View {
        if viewModel.isLoading && viewModel.scheduledBroadcasts.isEmpty {
            ProgressView()
                .tint(.white)
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
        } else {
            if viewModel.scheduledBroadcasts.isEmpty {
                VStack {
                    Spacer(minLength: 100)
                    EmptyProfileStateView()
                    Spacer(minLength: 100)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.scheduledBroadcasts) { broadcast in
                        BroadcastCardView(
                            broadcast: .scheduled(broadcast),
                            showsMenuButton: false,
                            showsNotificationButton: true,
                            isNotificationSubscribed: pushManager.isSubscribedToRoom(broadcast.id),
                            onNotificationTap: {
                                toggleRoomNotification(roomId: broadcast.id)
                            },
                            onMenuTap: {}
                        )
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.top, 12)
            }
        }
    }

    private func toggleRoomNotification(roomId: String) {
        Task {
            await pushManager.requestPermissionAndRegister()
            do {
                try await pushManager.toggleRoomSubscription(roomId: roomId)
            } catch {
                print("DEBUG: Oda bildirim aboneliği değiştirilemedi: \(error.localizedDescription)")
            }
        }
    }

    private var followButtonTitle: String {
        if viewModel.isBlocked {
            return "Engellendi"
        }

        return viewModel.isFollowing ? "Takip Ediliyor" : "Takip Et"
    }
}

private struct UserStatItem: View {
    let count: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(count)
                .font(.manrope(.bold, size: 16))
                .foregroundColor(.white)
            Text(label)
                .font(.manrope(.medium, size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

private struct EmptyProfileStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Maalesef")
                .font(.manrope(.bold, size: 24))
                .foregroundColor(.white)
            
            Text("burada hiçbir şey yok!")
                .font(.manrope(.bold, size: 24))
                .foregroundColor(.white)
        }
        .multilineTextAlignment(.center)
    }
}

private struct UserOptionsPopUp: View {
    let isFollowing: Bool
    let isFavorite: Bool
    let isBlocked: Bool
    let isFavoriteRequestInProgress: Bool
    let isBlockingUser: Bool
    let onDismiss: () -> Void
    let onFavoriteTap: () -> Void
    let onShareTap: () -> Void
    let onFollowTap: () -> Void
    let onReportTap: () -> Void
    let onBlockTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isBlocked {
                OptionItem(
                    icon: "Shield Fail",
                    title: isBlockingUser ? "İşleniyor..." : "Engeli Kaldır",
                    isDestructive: true,
                    action: onBlockTap
                )
            } else {
                OptionItem(
                    icon: isFavorite ? "star.fill" : "star",
                    title: isFavoriteRequestInProgress
                        ? "İşleniyor..."
                        : (isFavorite ? "Favorilerden Çıkar" : "Favorilere Ekle"),
                    action: onFavoriteTap
                )
                Divider().background(Color.white.opacity(0.1))
                OptionItem(icon: "share", title: "Hesabı Paylaş", action: onShareTap)
                Divider().background(Color.white.opacity(0.1))
                OptionItem(
                    icon: isFollowing ? "person.badge.minus" : "person.badge.plus",
                    title: isFollowing ? "Takipten Çık" : "Takip Et",
                    action: onFollowTap
                )
                Divider().background(Color.white.opacity(0.1))
                OptionItem(icon: "Danger Circle", title: "Şikayet Et", action: onReportTap)
                Divider().background(Color.white.opacity(0.1))
                OptionItem(
                    icon: "Shield Fail",
                    title: isBlockingUser ? "İşleniyor..." : "Engelle",
                    isDestructive: true,
                    action: onBlockTap
                )
            }
        }
        .frame(maxWidth: 320)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(red: 0.12, green: 0.12, blue: 0.12)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(.top, 80)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    
    private func OptionItem(icon: String, title: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Spacer()
                
                // İkon check: System name mi yoksa asset mi?
                if UIImage(systemName: icon) != nil {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                } else {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                
                Text(title)
                    .font(.manrope(.medium, size: 16))
                
                Spacer()
            }
            .foregroundColor(isDestructive ? .red : .white)
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    OtherUserProfileView(userId: "123", name: "Ahmet Öz", username: "@ahmetoz")
        .preferredColorScheme(.dark)
}
