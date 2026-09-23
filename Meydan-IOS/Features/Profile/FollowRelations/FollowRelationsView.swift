import SwiftUI

struct FollowRelationsView: View {
    @StateObject var viewModel: FollowRelationsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUserForOptions: FollowUser? = nil
    @State private var selectedUserForReport: FollowUser? = nil
    let showsUserOptions: Bool

    init(viewModel: FollowRelationsViewModel, showsUserOptions: Bool = true) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.showsUserOptions = showsUserOptions
    }
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            GeometryReader { geometry in
                let safeWidth = geometry.size.width.isFinite ? max(geometry.size.width, 0) : 0
                let horizontalPadding = min(max(safeWidth * 0.045, 16), 24)
                let contentMaxWidth = min(max(safeWidth - (horizontalPadding * 2), 0), 560)

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
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Spacer()
                    }
                    .padding(.horizontal, 8)
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
                            .padding(.horizontal, 8)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.users) { user in
                                    FollowUserRow(
                                        user: user,
                                        showsMenuButton: showsUserOptions,
                                        onMenuTap: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedUserForOptions = user
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.bottom, 30)
                        }
                    }
                }
                .frame(maxWidth: contentMaxWidth, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, horizontalPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .blur(radius: selectedUserForOptions != nil ? 2 : 0) // Optional slight blur for focus
            }
            
            // Options Pop-up Overlay
            if showsUserOptions, selectedUserForOptions != nil {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { selectedUserForOptions = nil }
                    }
                
                OptionsMenuPopUp(
                    relationType: viewModel.type,
                    isPerformingAction: viewModel.isPerformingAction,
                    onAddFavorite: {
                        guard let user = selectedUserForOptions else { return }
                        withAnimation { selectedUserForOptions = nil }
                        Task { await viewModel.addFavorite(user) }
                    },
                    onUnfollow: {
                        guard let user = selectedUserForOptions else { return }
                        withAnimation { selectedUserForOptions = nil }
                        Task { await viewModel.unfollow(user) }
                    },
                    onReport: {
                        selectedUserForReport = selectedUserForOptions
                        withAnimation { selectedUserForOptions = nil }
                    },
                    onBlock: {
                        guard let user = selectedUserForOptions else { return }
                        withAnimation { selectedUserForOptions = nil }
                        Task { await viewModel.block(user) }
                    }
                )
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }

            if let selectedUserForReport {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    ReportView(
                        viewModel: ReportViewModel(
                            context: .user(
                                userId: selectedUserForReport.id,
                                username: selectedUserForReport.username.replacingOccurrences(of: "@", with: "")
                            )
                        ),
                        onDismiss: {
                            withAnimation { self.selectedUserForReport = nil }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.fetchUsers()
        }
        .alert(
            "İşlem tamamlanamadı",
            isPresented: Binding(
                get: { viewModel.actionErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.actionErrorMessage = nil
                    }
                }
            )
        ) {
            Button("Tamam", role: .cancel) {
                viewModel.actionErrorMessage = nil
            }
        } message: {
            Text(viewModel.actionErrorMessage ?? "Bilinmeyen bir hata oluştu.")
        }
    }
}

private struct FollowUserRow: View {
    let user: FollowUser
    let showsMenuButton: Bool
    let onMenuTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            NavigationLink {
                OtherUserProfileView(
                    userId: user.id,
                    name: user.name,
                    username: user.username
                )
            } label: {
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
                            .lineLimit(1)
                        Text(user.username)
                            .font(.manrope(.medium, size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if showsMenuButton {
                // Menu
                Button(action: onMenuTap) {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
    let isPerformingAction: Bool
    let onAddFavorite: () -> Void
    let onUnfollow: () -> Void
    let onReport: () -> Void
    let onBlock: () -> Void
    
    var unfollowText: String {
        relationType == .followers ? "Takipçiyi Çıkar" : "Takipten Çık"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            OptionRow(icon: "star", text: "Favorilere Ekle", isDisabled: isPerformingAction, action: onAddFavorite)
            
            Divider().background(Color.white.opacity(0.1))
            
            OptionRow(icon: "person.badge.minus", text: unfollowText, isDisabled: isPerformingAction, action: onUnfollow)
            
            Divider().background(Color.white.opacity(0.1))
            
            OptionRow(icon: "exclamationmark.circle", text: "Şikayet Et", isDisabled: isPerformingAction, action: onReport)
            
            Divider().background(Color.white.opacity(0.1))
            
            OptionRow(icon: "xmark.shield", text: "Engelle", isDisabled: isPerformingAction, action: onBlock)
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
    var isDisabled: Bool = false
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
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
    }
}

#Preview {
    FollowRelationsView(viewModel: FollowRelationsViewModel(type: .followers))
}
