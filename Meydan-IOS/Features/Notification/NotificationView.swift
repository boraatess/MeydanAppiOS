import SwiftUI

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @State private var chatDestination: ChatDestination?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                let safeWidth = geometry.size.width.isFinite ? max(geometry.size.width, 0) : 0
                let horizontalPadding = min(max(safeWidth * 0.045, 16), 24)
                let contentMaxWidth = min(max(safeWidth - (horizontalPadding * 2), 0), 560)

                VStack(spacing: 8) {
                    
                    header

                    if viewModel.isLoading && viewModel.notifications.isEmpty {
                        Spacer(minLength: 0)
                        ProgressView()
                            .tint(.white)
                        Spacer(minLength: 0)
                    } else if let errorMessage = viewModel.errorMessage, viewModel.notifications.isEmpty {
                        Spacer(minLength: 0)
                        VStack(spacing: 12) {
                            Text(errorMessage)
                                .font(.manrope(.medium, size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            Button("Tekrar Dene") {
                                viewModel.fetchNotifications()
                            }
                            .font(.manrope(.semiBold, size: 14))
                            .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer(minLength: 0)
                    } else if viewModel.notifications.isEmpty {
                        Spacer(minLength: 0)
                        EmptyNotificationView()
                            .frame(maxWidth: .infinity)
                        Spacer(minLength: 0)
                    } else {
                        notificationList
                    }
                }
                .frame(
                    maxWidth: contentMaxWidth,
                    maxHeight: .infinity,
                    alignment: .top
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true)
            .overlay(alignment: .top) {
                if let roomAccessMessage = viewModel.roomAccessMessage {
                    TransientToastView(message: roomAccessMessage)
                        .padding(.top, 12)
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
            .padding(.horizontal, 8)
            .padding(.top, 8)
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
            .alert("Bilgilendirme", isPresented: Binding(
                get: { viewModel.expiredRoomMessage != nil },
                set: { if !$0 { viewModel.expiredRoomMessage = nil } }
            )) {
                Button("Tamam", role: .cancel) {
                    viewModel.expiredRoomMessage = nil
                }
            } message: {
                Text(viewModel.expiredRoomMessage ?? "")
            }
            .onAppear {
                viewModel.fetchNotifications()
            }
            .refreshable {
                await viewModel.refreshAndMarkAllAsRead()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            
            Text("Bildirimler")
                .font(.manrope(.bold, size: 18))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            
            Spacer()
            
            Button(action: {
                viewModel.markAllAsRead()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                        .frame(width: 48, height: 48)
                    
                    Image("mdi_bell-check")
                        .font(.system(size: 24))
                    
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        
    }

    private var notificationList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 16) {
                if !viewModel.last7DaysNotifications.isEmpty {
                    sectionHeader("Son 7 gün")
                    notificationSection(viewModel.last7DaysNotifications)
                }

                if !viewModel.last30DaysNotifications.isEmpty {
                    sectionHeader("Son 30 gün")
                    notificationSection(viewModel.last30DaysNotifications)
                }

                if !viewModel.olderNotifications.isEmpty {
                    sectionHeader("Daha eski")
                    notificationSection(viewModel.olderNotifications)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.top, 8)
    }

    private func notificationSection(_ items: [NotificationItem]) -> some View {
        VStack(spacing: 8) {
            ForEach(items) { notification in
                NotificationRow(
                    notification: notification,
                    isActionLoading: viewModel.actionLoadingNotificationId == notification.id,
                    onActionTap: {
                        handleNotificationAction(notification)
                    }
                )
                    .onTapGesture {
                        withAnimation {
                            viewModel.markAsRead(notification)
                        }
                    }
            }
        }
    }

    private func handleNotificationAction(_ notification: NotificationItem) {
        viewModel.markAsRead(notification)

        switch notification.actionKind {
        case .openProfile:
            if let destination = viewModel.profileDestination(for: notification) {
                navigationPath.append(destination)
            }
        case .openRoom, .browseRoom:
            Task {
                chatDestination = await viewModel.chatDestination(for: notification)
            }
        case .expiredRoom:
            viewModel.expiredRoomMessage = "Bu sohbet odasının süresi dolmuş veya oda sona ermiş."
        case .none:
            break
        }
    }
}

// MARK: - Bildirim Satırı Tasarımı
struct NotificationRow: View {
    let notification: NotificationItem
    var isActionLoading: Bool = false
    var onActionTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                notificationAvatar
                    .frame(width: 36, height: 36)
                    .fixedSize()

                VStack(alignment: .leading, spacing: 8) {
                    (Text(notification.title)
                        .font(.manrope(.bold, size: 14))
                        .foregroundColor(.white)
                    + Text(" \(notification.message)")
                        .font(.manrope(.regular, size: 14))
                        .foregroundColor(.white))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Spacer()
                        Text(notification.time)
                            .font(.manrope(.regular, size: 11))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let buttonTitle = notification.buttonTitle, notification.buttonStyle != .none {
                Button(action: onActionTap) {
                    ZStack {
                        Text(buttonTitle)
                            .opacity(isActionLoading ? 0 : 1)

                        if isActionLoading {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .font(.manrope(.semiBold, size: 14))
                    .foregroundColor(notification.buttonStyle == .disabled ? .white.opacity(0.75) : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(actionBackgroundColor)
                    .cornerRadius(12)
                }
                .disabled(isActionLoading)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(notification.isRead ? Color(hex: "#1B1B1B") : Color(hex: "#363636"))
        .cornerRadius(16)
        .clipped()
    }

    private var actionBackgroundColor: Color {
        switch notification.buttonStyle {
        case .disabled:
            return Color(white: 0.5)
        case .active:
            return notification.buttonTitle == "Gözat" ? Color(red: 0.73, green: 0.25, blue: 0.22) : Color.branding
        case .none:
            return .clear
        }
    }

    @ViewBuilder
    private var notificationAvatar: some View {
        if let url = URL(string: notification.imageUrl), url.scheme != nil {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    defaultAvatar
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
        } else {
            defaultAvatar
        }
    }

    private var defaultAvatar: some View {
        Image(systemName: notification.imageUrl.contains(".") ? "person.crop.circle.fill" : notification.imageUrl)
            .resizable()
            .scaledToFit()
            .frame(width: 36, height: 36)
            .foregroundStyle(.gray)
            .background(Color(.systemGray6))
            .clipShape(Circle())
    }
}

// MARK: - Boş Durum Tasarımı
struct EmptyNotificationView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Henüz bildirim yok!")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Text("Yeni bildirimler olduğunda burada\ngöreceksin")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
            .preferredColorScheme(.dark)
    }
}
