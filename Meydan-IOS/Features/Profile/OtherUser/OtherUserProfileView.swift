import SwiftUI

struct OtherUserProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: OtherUserProfileViewModel
    @State private var showOptions = false
    @State private var selectedTab: ProfileTab = .scheduled
    
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
    
    enum ProfileTab {
        case scheduled, past
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
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
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
                                        NavigationLink(
                                            value: ProfileNavigation.followers(userId: viewModel.userProfile.id)
                                        ) {
                                            UserStatItem(count: "\(viewModel.userProfile.followersCount)", label: "takipçi")
                                        }
                                        NavigationLink(
                                            value: ProfileNavigation.following(userId: viewModel.userProfile.id)
                                        ) {
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
                                Task { await viewModel.toggleFollow() }
                            } label: {
                                Group {
                                    if viewModel.isFollowRequestInProgress {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text(viewModel.isFollowing ? "Takip Ediliyor" : "Takip Et")
                                    }
                                }
                                    .font(.manrope(.bold, size: 16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(viewModel.isFollowing ? Color.white.opacity(0.1) : Color.white.opacity(0.15))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            .disabled(viewModel.isFollowRequestInProgress || viewModel.isLoading)

                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.manrope(.medium, size: 13))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // Tabs Section
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                HeaderTabButton(title: "Planlanan Yayınlar", isSelected: selectedTab == .scheduled) {
                                    selectedTab = .scheduled
                                }
                                HeaderTabButton(title: "Geçmiş Yayınlar", isSelected: selectedTab == .past) {
                                    selectedTab = .past
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            profileContent
                        }
                    }
                }
            }
            .blur(radius: showOptions ? 2 : 0)
            
            // Options Overlay
            if showOptions {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showOptions = false }
                    }
                
                UserOptionsPopUp(isFollowing: viewModel.isFollowing, onDismiss: { withAnimation { showOptions = false } })
                    .transition(.scale(scale: 0.9, anchor: .topTrailing).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .padding(.horizontal, 16)
        .navigationBarHidden(true)
        .task {
            await viewModel.load()
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
        if viewModel.isLoading && viewModel.scheduledBroadcasts.isEmpty && viewModel.pastBroadcasts.isEmpty {
            ProgressView()
                .tint(.white)
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
        } else {
            let broadcastsAreEmpty = selectedTab == .scheduled
                ? viewModel.scheduledBroadcasts.isEmpty
                : viewModel.pastBroadcasts.isEmpty

            if broadcastsAreEmpty {
                VStack {
                    Spacer(minLength: 100)
                    EmptyProfileStateView()
                    Spacer(minLength: 100)
                }
                .frame(maxWidth: .infinity)
            } else if selectedTab == .scheduled {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.scheduledBroadcasts) { broadcast in
                        BroadcastCardView(broadcast: .scheduled(broadcast), onMenuTap: {})
                    }
                }
                .padding(.top, 12)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.pastBroadcasts) { broadcast in
                        BroadcastCardView(broadcast: .past(broadcast), onMenuTap: {})
                    }
                }
                .padding(.top, 12)
            }
        }
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

private struct HeaderTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(title)
                    .font(.manrope(.bold, size: 16))
                    .foregroundColor(isSelected ? Color.branding : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
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
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            OptionItem(icon: "star", title: "Favorilere Ekle")
            Divider().background(Color.white.opacity(0.1))
            OptionItem(icon: "share", title: "Hesabı Paylaş")
            Divider().background(Color.white.opacity(0.1))
            OptionItem(icon: "person.badge.minus", title: "Takipten Çık")
            Divider().background(Color.white.opacity(0.1))
            OptionItem(icon: "Danger Circle", title: "Şikayet Et")
            Divider().background(Color.white.opacity(0.1))
            OptionItem(icon: "Shield Fail", title: "Engelle", isDestructive: false)
        }
        .frame(width: 320)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(red: 0.12, green: 0.12, blue: 0.12)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(.top, 80)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    
    private func OptionItem(icon: String, title: String, isDestructive: Bool = false) -> some View {
        Button(action: onDismiss) {
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
