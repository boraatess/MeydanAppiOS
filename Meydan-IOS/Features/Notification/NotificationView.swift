import SwiftUI

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                VStack(spacing: 16) {
                    header
                }

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
                    Spacer(minLength: 0)
                } else if viewModel.notifications.isEmpty {
                    Spacer(minLength: 0)
                    EmptyNotificationView()
                    Spacer(minLength: 0)
                } else {
                    notificationList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(16)
            .background(Color.background.ignoresSafeArea(edges: .bottom))
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchNotifications()
            }
            .refreshable {
                viewModel.fetchNotifications()
            }
        }
        .padding(.horizontal, 16)
        
    }

    private var header: some View {
        HStack(spacing: 16) {

            Text("Bildirimler")
                .font(.manrope(.bold, size: 18))
                .foregroundColor(.white)

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
        .padding(8)
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
            .padding(.bottom)
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
                NotificationRow(notification: notification)
                    .onTapGesture {
                        withAnimation {
                            viewModel.markAsRead(notification)
                        }
                    }
            }
        }
    }
}

// MARK: - Bildirim Satırı Tasarımı
struct NotificationRow: View {
    let notification: NotificationItem

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                notificationAvatar

                VStack(alignment: .leading, spacing: 8) {
                    Text(notification.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    + Text(" \(notification.message)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white)

                    HStack {
                        Spacer()
                        Text(notification.time)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.gray)
                    }
                }
            }

            if let buttonTitle = notification.buttonTitle, notification.buttonStyle != .none {
                Button(action: {}) {
                    Text(buttonTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(notification.buttonStyle == .disabled ? .gray : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(notification.buttonStyle == .disabled ? Color(white: 0.25) : Color.branding)
                        .cornerRadius(12)
                }
                .disabled(notification.buttonStyle == .disabled)
            }
        }
        .padding(16)
        .background(notification.isRead ? Color(white: 0.15) : Color(white: 0.22))
        .cornerRadius(16)
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
