import SwiftUI

struct FollowRelationsView: View {
    @StateObject var viewModel: FollowRelationsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUserForOptions: FollowUser? = nil
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    
                    Text(viewModel.title)
                        .font(.manrope(.bold, size: 20))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.branding)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    Text(errorMessage)
                        .font(.manrope(.medium, size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.users) { user in
                                FollowUserRow(user: user) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedUserForOptions = user
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    }
                }
            }
            .blur(radius: selectedUserForOptions != nil ? 2 : 0) // Optional slight blur for focus
            
            // Options Pop-up Overlay
            if selectedUserForOptions != nil {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { selectedUserForOptions = nil }
                    }
                
                OptionsMenuPopUp(
                    relationType: viewModel.type,
                    onDismiss: { withAnimation { selectedUserForOptions = nil } }
                )
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.fetchUsers()
        }
    }
}

private struct FollowUserRow: View {
    let user: FollowUser
    let onMenuTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Group {
                if let source = user.profileImageURL,
                   let url = URL(string: source),
                   url.scheme != nil {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            fallbackAvatar
                        }
                    }
                } else {
                    fallbackAvatar
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.manrope(.bold, size: 16))
                    .foregroundColor(.white)
                Text(user.username)
                    .font(.manrope(.medium, size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Menu
            Button(action: onMenuTap) {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .padding(8)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var fallbackAvatar: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFill()
            .foregroundColor(.grayMedium)
    }
}

private struct OptionsMenuPopUp: View {
    let relationType: FollowRelationsViewModel.RelationType
    let onDismiss: () -> Void
    
    var unfollowText: String {
        relationType == .followers ? "Takipten Çık" : "Takipten Çıkar"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            OptionRow(icon: "star", text: "Favorilere Ekle", action: onDismiss)
            
            Divider().background(Color.white.opacity(0.1))
            
            OptionRow(icon: "person.badge.minus", text: unfollowText, action: onDismiss)
            
            Divider().background(Color.white.opacity(0.1))
            
            OptionRow(icon: "exclamationmark.circle", text: "Şikayet Et", action: onDismiss)
            
            Divider().background(Color.white.opacity(0.1))
            
            OptionRow(icon: "xmark.shield", text: "Engelle", action: onDismiss)
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

private struct OptionRow: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text(text)
                    .font(.manrope(.medium, size: 16))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FollowRelationsView(viewModel: FollowRelationsViewModel(type: .followers))
}
