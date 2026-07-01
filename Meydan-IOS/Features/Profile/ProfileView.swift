import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var optionsPopupVisibleForID: String? = nil
    
    @Binding var path: [ProfileNavigation]
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 8) {
                VStack(spacing: 16) {
                    if let user = viewModel.userProfile {
                        ProfileHeaderSection(user: user, onShareTapped: {
                            viewModel.fetchShareURL(username: user.username)
                        })

                        Divider()
                            .background(Color.grayDark)
                    }

                    TabSwitcherView(selectedTab: $viewModel.selectedTab)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
                .padding(.horizontal, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        AdMobBannerAdView(adUnitID: AdMobConfig.homeBannerAdUnitID)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 4)

                        switch viewModel.selectedTab {
                        case .scheduled:
                            ForEach(viewModel.scheduledBroadcasts) { broadcast in
                                BroadcastCardView(broadcast: .scheduled(broadcast)) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        optionsPopupVisibleForID = broadcast.id.uuidString
                                    }
                                }
                            }
                        case .past:
                            ForEach(viewModel.pastBroadcasts) { broadcast in
                                BroadcastCardView(broadcast: .past(broadcast)) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        optionsPopupVisibleForID = broadcast.id.uuidString
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(8)
            .background(Color.background.ignoresSafeArea(edges: .bottom))
            .blur(radius: optionsPopupVisibleForID != nil ? 2 : 0)
            .task {
                await viewModel.onAppear()
            }
            .padding(.horizontal, 16)
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
                            onDismiss: { withAnimation { optionsPopupVisibleForID = nil } }
                        )
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                }
            }
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
    }
}

enum ProfileNavigation: Hashable {
    case followers(userId: String), following(userId: String), settings(user: UserProfile), personalInfo(user: UserProfile), accountSettings(user: UserProfile), contactUs, passwordRenewal, deleteAccount, blockedUsers, emailUpdate, emailVerification(email: String), deactivateAccount, otherProfile(userId: String, name: String, username: String)
}

// MARK: - Header Section
private struct ProfileHeaderSection: View {
    let user: UserProfile
    let onShareTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // First Row: Avatar, Name, Stats & Icons
            HStack(alignment: .top, spacing: 20) {
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
                .frame(width: 100, height: 100)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 12) {
                    // Name and Icons
                    HStack {
                        Text(user.name)
                            .font(.manrope(.bold, size: 24))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
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
                    }
                    
                    // Stats
                    HStack(spacing: 24) {
                        StatItem(count: "\(user.streamCount)", label: "yayın")
                        
                        NavigationLink(value: ProfileNavigation.followers(userId: user.id)) {
                            StatItem(count: "\(user.followersCount)", label: "takipçi")
                        }
                        
                        NavigationLink(value: ProfileNavigation.following(userId: user.id)) {
                            StatItem(count: "\(user.followingCount)", label: "takip")
                        }
                    }
                }
            }
            
            // Second Row: Bio Details
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.manrope(.bold, size: 16))
                    .foregroundColor(.white)
                
                Text(user.bio)
                    .font(.manrope(.medium, size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
        }
    }
}

private struct StatItem: View {
    let count: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(count)
                .font(.manrope(.bold, size: 18))
                .foregroundColor(.white)
            Text(label)
                .font(.manrope(.medium, size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Tab Switcher
private struct TabSwitcherView: View {
    @Binding var selectedTab: ProfileViewModel.ProfileTab
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "Planlanan Yayınlar", isSelected: selectedTab == .scheduled) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = .scheduled
                }
            }
            
            TabButton(title: "Geçmiş Yayınlar", isSelected: selectedTab == .past) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = .past
                }
            }
        }
    }
}

/*
private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Text(title)
            .font(.manrope(.bold, size: 16))
            .foregroundColor(isSelected ? .branding : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.001)) // Hit-testable area
            .onTapGesture {
                action()
            }
    }
}
*/

private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.manrope(.bold, size: 16))
                .foregroundColor(isSelected ? .branding : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// Removed old BroadcastCardView and CustomCardView - using the dedicated component now.

// MARK: - Broadcast Options Pop-up
private struct BroadcastOptionsPopUp: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onDismiss) {
                Text("Yayını Şimdi Başlat")
                    .font(.manrope(.medium, size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Divider().background(Color.white.opacity(0.1))
            
            Button(action: onDismiss) {
                Text("Yayını Düzenle")
                    .font(.manrope(.medium, size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Divider().background(Color.white.opacity(0.1))
            
            Button(action: onDismiss) {
                Text("Yayını Sil")
                    .font(.manrope(.medium, size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.12)) // Dark modal background
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal, 40)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
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
