import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var optionsPopupVisibleForID: String? = nil
    @State private var editingBroadcast: ScheduledBroadcast? = nil
    @State private var chatDestination: ChatDestination? = nil
    @State private var broadcastOptionsKind: BroadcastOptionsKind = .scheduled
    
    @Binding var path: [ProfileNavigation]
    
    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geometry in
                let safeWidth = geometry.size.width.isFinite ? max(geometry.size.width, 0) : 0
                let horizontalPadding = min(max(safeWidth * 0.045, 16), 24)
                let contentMaxWidth = min(max(safeWidth - (horizontalPadding * 2), 0), 560)

                VStack(spacing: 8) {
                    VStack(spacing: 16) {
                        if let user = viewModel.userProfile {
                            ProfileHeaderSection(user: user, onShareTapped: {
                                viewModel.fetchShareURL(username: user.username)
                            })

                            Divider()
                                .background(Color.grayDark)
                        }

                        BroadcastSectionTitle()
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 14)
                    .padding(.horizontal, 8)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            if viewModel.scheduledBroadcasts.isEmpty {
                                VStack {
                                    Spacer(minLength: 100)
                                    EmptyProfileBroadcastStateView()
                                    Spacer(minLength: 100)
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                ForEach(viewModel.scheduledBroadcasts) { broadcast in
                                    BroadcastCardView(broadcast: .scheduled(broadcast)) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            broadcastOptionsKind = .scheduled
                                            optionsPopupVisibleForID = broadcast.id
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                        .padding(.bottom)
                    }
                    .pullToRefresh {
                        await viewModel.fetchData(force: true)
                    }
                }
                .frame(maxWidth: contentMaxWidth, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(Color.black.ignoresSafeArea(edges: .bottom))
            .blur(radius: optionsPopupVisibleForID != nil ? 2 : 0)
            .task {
                await viewModel.onAppear()
            }
            .navigationBarHidden(true)
            .overlay {
                if optionsPopupVisibleForID != nil {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation { optionsPopupVisibleForID = nil }
                            }

                        BroadcastOptionsPopUp(
                            kind: broadcastOptionsKind,
                            isStartingRoom: viewModel.isStartingRoom,
                            isDeletingRoom: viewModel.isDeletingRoom,
                            onDismiss: { withAnimation { optionsPopupVisibleForID = nil } },
                            onStart: {
                                guard let selectedID = optionsPopupVisibleForID,
                                      let broadcast = viewModel.scheduledBroadcasts.first(where: { $0.id == selectedID }) else {
                                    withAnimation { optionsPopupVisibleForID = nil }
                                    return
                                }

                                withAnimation { optionsPopupVisibleForID = nil }
                                Task {
                                    let didStart = await viewModel.startRoom(id: selectedID)
                                    if didStart {
                                        let destination = ChatDestination(
                                            roomId: selectedID,
                                            roomTitle: broadcast.title,
                                            roomOwnerUsername: viewModel.userProfile?.username ?? "",
                                            roomOwnerUserId: viewModel.userID
                                        )
                                        chatDestination = destination
                                        await viewModel.fetchData(force: true)
                                    }
                                }
                            },
                            onEdit: {
                                guard let selectedID = optionsPopupVisibleForID,
                                      let broadcast = viewModel.scheduledBroadcasts.first(where: { $0.id == selectedID }) else {
                                    withAnimation { optionsPopupVisibleForID = nil }
                                    return
                                }

                                editingBroadcast = broadcast
                                withAnimation { optionsPopupVisibleForID = nil }
                            },
                            onDelete: {
                                guard let selectedID = optionsPopupVisibleForID else {
                                    withAnimation { optionsPopupVisibleForID = nil }
                                    return
                                }

                                withAnimation { optionsPopupVisibleForID = nil }
                                Task {
                                    _ = await viewModel.deleteRoom(id: selectedID)
                                }
                            }
                        )
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 8)
            .navigationDestination(for: ProfileNavigation.self) { destination in
                switch destination {
                case .followers(let userId):
                    FollowRelationsView(viewModel: FollowRelationsViewModel(type: .followers, userId: userId))
                case .following(let userId):
                    FollowRelationsView(viewModel: FollowRelationsViewModel(type: .following, userId: userId))
                case .settings(let user):
                    SettingsView(user: user)
                case .personalInfo(let user):
                    PersonalInfoView(user: user)
                case .contactUs:
                    ContactUsView()
                case .accountSettings(let user):
                    AccountSettingsView(user: user)
                case .passwordRenewal:
                    PasswordRenewalView()
                case .deleteAccount:
                    DeleteAccountView()
                case .blockedUsers:
                    BlockedUsersView()
                case .emailUpdate:
                    EmailUpdateView()
                case .emailVerification(let email):
                    EmailVerificationView(email: email)
                case .deactivateAccount:
                    DeactivateAccountView()
                case .otherProfile(let userId, let name, let username):
                    OtherUserProfileView(userId: userId, name: name, username: username)
                }
            }
            
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.shareURL {
                ShareActivityView(items: [url])
            }
        }
        .fullScreenCover(item: $editingBroadcast) { broadcast in
            CreateRoomView(
                mode: .edit(
                    EditRoomData(
                        roomId: broadcast.id,
                        title: broadcast.title,
                        date: broadcast.scheduledDate,
                        categoryId: broadcast.categoryId,
                        categoryName: broadcast.categoryName,
                        imageURL: broadcast.imageURL
                    )
                ),
                onBack: {
                    editingBroadcast = nil
                    Task {
                        await viewModel.fetchData(force: true)
                    }
                }
            )
        }
        .alert(viewModel.deleteRoomErrorMessage != nil ? "Yayın silinemedi" : "Yayın başlatılamadı", isPresented: Binding(
            get: { viewModel.startRoomErrorMessage != nil || viewModel.deleteRoomErrorMessage != nil },
            set: { if !$0 { viewModel.startRoomErrorMessage = nil; viewModel.deleteRoomErrorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) {
                viewModel.startRoomErrorMessage = nil
                viewModel.deleteRoomErrorMessage = nil
            }
        } message: {
            Text(viewModel.deleteRoomErrorMessage ?? viewModel.startRoomErrorMessage ?? "")
        }
        .loadingOverlay(isPresented: $viewModel.isStartingRoom, message: "Yayın açılıyor...")
        .fullScreenCover(item: $chatDestination) { destination in
            ChatView(
                roomId: destination.roomId,
                roomTitle: destination.roomTitle,
                roomOwnerUsername: destination.roomOwnerUsername,
                roomOwnerUserId: destination.roomOwnerUserId
            )
        }
    }
}

enum ProfileNavigation: Hashable {
    case followers(userId: String), following(userId: String), settings(user: UserProfile), personalInfo(user: UserProfile), accountSettings(user: UserProfile), contactUs, passwordRenewal, deleteAccount, blockedUsers, emailUpdate, emailVerification(email: String), deactivateAccount, otherProfile(userId: String, name: String, username: String)
}

private enum BroadcastOptionsKind: Equatable {
    case scheduled
    case past
}

// MARK: - Header Section
private struct ProfileHeaderSection: View {
    let user: UserProfile
    let onShareTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // First Row: Avatar, Name, Stats & Icons
            HStack(alignment: .top, spacing: 12) {
                // Avatar
                Group {
                    if user.profileImageURL.starts(with: "http") {
                        AsyncImage(url: URL(string: user.profileImageURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            default:
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(width: 76, height: 76)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 12) {
                    // Name and Icons
                    HStack(spacing: 8) {
                        Text(user.name)
                            .font(.manrope(.bold, size: 20))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .truncationMode(.tail)
                            .layoutPriority(1)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            // Profili Paylaş: /user/share/{username}
                            Button(action: onShareTapped) {
                                Image("share")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            
                            NavigationLink(value: ProfileNavigation.settings(user: user)) {
                                Image("Setting")
                                    .resizable()
                                    .renderingMode(.template)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.white)
                            }
                        }
                        .fixedSize()
                    }
                    
                    // Stats
                    HStack(spacing: 10) {
                        StatItem(count: "\(user.streamCount)", label: "yayın")
                        
                        NavigationLink(value: ProfileNavigation.followers(userId: user.id)) {
                            StatItem(count: "\(user.followersCount)", label: "takipçi")
                        }
                        
                        NavigationLink(value: ProfileNavigation.following(userId: user.id)) {
                            StatItem(count: "\(user.followingCount)", label: "takip")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Second Row: Bio Details
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.manrope(.bold, size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(user.bio)
                    .font(.manrope(.medium, size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StatItem: View {
    let count: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(count)
                .font(.manrope(.bold, size: 16))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.manrope(.medium, size: 12))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(minWidth: 42, alignment: .leading)
    }
}

private struct BroadcastSectionTitle: View {
    
    var body: some View {
        Text("Canlı & Planlanan Yayınlar")
            .font(.manrope(.bold, size: 18))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
            .padding(.bottom, 2)
    }
}

private struct EmptyProfileBroadcastStateView: View {
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

// Removed old BroadcastCardView and CustomCardView - using the dedicated component now.

// MARK: - Broadcast Options Pop-up
private struct BroadcastOptionsPopUp: View {
    let kind: BroadcastOptionsKind
    let isStartingRoom: Bool
    let isDeletingRoom: Bool
    let onDismiss: () -> Void
    let onStart: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            switch kind {
            case .scheduled:
                optionButton(title: isStartingRoom ? "Yayın Başlatılıyor..." : "Yayını Şimdi Başlat", action: onStart)
                optionDivider
                optionButton(title: "Yayını Düzenle", action: onEdit)
                optionDivider
                optionButton(title: isDeletingRoom ? "Yayın Siliniyor..." : "Yayını Sil", isDestructive: true, action: onDelete)
            case .past:
                pastDeleteButton
            }
	        }
        .disabled(isStartingRoom || isDeletingRoom)
        .padding(.vertical, kind == .past ? 0 : 8)
        .frame(maxWidth: 310)
        .background(backgroundShape)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(kind == .past ? 0 : 0.05), lineWidth: 1)
        )
        .padding(.horizontal, 40)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
    }

    @ViewBuilder
    private var backgroundShape: some View {
        if kind == .past {
            Color.clear
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
        }
    }

    private var pastDeleteButton: some View {
        Button(action: onDelete) {
            Text(isDeletingRoom ? "Yayın Siliniyor..." : "Yayını Sil")
                .font(.manrope(.medium, size: 14))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var optionDivider: some View {
        Divider().background(Color.white.opacity(0.1))
    }

    private func optionButton(title: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.manrope(.medium, size: 16))
                .foregroundColor(isDestructive ? Color(hex: "#FF5C5C") : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    ProfileView(path: .constant([]))
        .preferredColorScheme(.dark)
        .environmentObject(AuthenticationManager())
        .environmentObject(AppFlowState())
}

// MARK: - BlurView Helper
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
