import SwiftUI

struct BlockedUsersView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BlockedUserViewModel()
    @State private var selectedUserForOptions: BlockedUser? = nil
    
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
                    
                    Text("Engellenenler")
                        .font(.manrope(.bold, size: 20))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // List
                if viewModel.isLoading && viewModel.blockedUsers.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Spacer()
                } else if viewModel.blockedUsers.isEmpty {
                    Spacer()
                    Text("Engellenen kullanıcı yok.")
                        .font(.manrope(.medium, size: 16))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.blockedUsers) { user in
                                BlockedUserRow(user: user) {
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
                
                UnblockMenuPopUp(
                    onDismiss: { withAnimation { selectedUserForOptions = nil } },
                    onUnblock: {
                        guard let user = selectedUserForOptions else { return }
                        withAnimation { selectedUserForOptions = nil }
                        Task {
                            await viewModel.unblockUser(userId: user.id)
                        }
                    }
                )
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .navigationBarHidden(true)
    }
}


private struct BlockedUserRow: View {
    let user: BlockedUser
    let onMenuTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar (Buraya Nuke / AsyncImage entegre edilebilir, şimdilik placeholder)
            if let avatar = user.avatar, !avatar.isEmpty, let url = URL(string: avatar) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else if phase.error != nil {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.grayMedium)
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .foregroundColor(.grayMedium)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(.manrope(.bold, size: 16))
                    .foregroundColor(.white)
                if let username = user.username {
                    Text(username.hasPrefix("@") ? username : "@\(username)")
                        .font(.manrope(.medium, size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
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
}

private struct UnblockMenuPopUp: View {
    let onDismiss: () -> Void
    let onUnblock: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onUnblock) {
                HStack(spacing: 8) {
                    Image(systemName: "slash.circle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Engeli Kaldır")
                        .font(.manrope(.bold, size: 16))
                        .foregroundColor(.white)
                }
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
        .padding(.horizontal, 60)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
    }
}

#Preview {
    BlockedUsersView()
        .preferredColorScheme(.dark)
}
