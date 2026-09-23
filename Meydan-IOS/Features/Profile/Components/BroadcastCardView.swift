import SwiftUI

enum BroadcastCardType {
    case scheduled(ScheduledBroadcast)
    case past(PastBroadcast)
}

struct BroadcastCardView: View {
    let broadcast: BroadcastCardType
    var width: CGFloat? = nil
    var showsMenuButton: Bool = true
    var showsNotificationButton: Bool = false
    var isNotificationSubscribed: Bool = false
    var onNotificationTap: () -> Void = {}
    let onMenuTap: () -> Void
    
    var body: some View {
        ZStack {
            // Arka plan: Kartın tamamını kaplayan zemin rengi
            Color(red: 0.08, green: 0.08, blue: 0.08) // Özgün tasarımdaki çok koyu gri-siyah zemin
            
            VStack(spacing: 0) {
                // Üst Kısım: Resim (Sadece üst yarısını kaplar ve aşağı doğru koyu renkte maskelenir)
                coverImageView
                    .frame(height: 220) // Resmin maksimum yüksekliği
                    .frame(maxWidth: .infinity)
                    .mask(imageFadeMask)
                    .clipped()
                
                Spacer()
            }
            
            // Tüm içerikleri tutan ön katman
            VStack(spacing: 0) {
                
                // Üst Satır: Planlandı Bilgisi ve Menü
                HStack(alignment: .top) {
                    if case .scheduled = broadcast {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(red: 0.94, green: 0.77, blue: 0.44)) // Sarımsı oval nokta
                                .frame(width: 20, height: 20)
                            Text("Planlandı")
                                .font(.manrope(.semiBold, size: 16))
                                .foregroundColor(.white)
                        }
                    } else {
                        Spacer()
                    }
                    
                    Spacer()
                    
                    if showsMenuButton {
                        Button(action: onMenuTap) {
                            Image(systemName: "ellipsis")
                                .rotationEffect(.degrees(90))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .zIndex(3)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 20)
                
                Spacer()
                
                // Alt Satır: Avatar, Başlık, Username ve Tarih Pill
                VStack(spacing: 16) {
                    // Profil ve Başlık Seti
                    HStack(spacing: 12) {
                        avatarImageView
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.manrope(.bold, size: 20))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Text(displayUsername)
                                .font(.manrope(.medium, size: 13))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)
                        
                        Spacer()
                    }
                    
                    // Koyu Gri Tarih Arka Planı (Pill)
                    HStack(spacing: 12) {
                        HStack {
                            Text(bottomText)
                                .font(.manrope(.bold, size: 16))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(height: 56)
                        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        if showsNotificationButton, case .scheduled = broadcast {
                            Button(action: onNotificationTap) {
                                Image(systemName: isNotificationSubscribed ? "bell.fill" : "bell")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(isNotificationSubscribed ? Color(red: 1, green: 0.45, blue: 0.4) : .white)
                                    .frame(width: 56, height: 56)
                                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
        .frame(maxWidth: width == nil ? .infinity : nil)
        .frame(width: width, height: 280) // Yeni dizaynda Date Box olduğu için biraz daha yüksek (280)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var title: String {
        switch broadcast {
        case .scheduled(let b): return b.title
        case .past(let b): return b.title
        }
    }
    
    private var bottomText: String {
        switch broadcast {
        case .scheduled(let b): return "\(b.date) \(b.time)"
        case .past: return "Geçmiş Yayın"
        }
    }
    
    private var coverImage: String {
        switch broadcast {
        case .scheduled(let b): return b.imageURL
        case .past(let p): return p.imageURL
        }
    }

    private var username: String {
        switch broadcast {
        case .scheduled(let b): return b.username
        case .past(let p): return p.username
        }
    }

    private var displayUsername: String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "@user" }
        return trimmed.hasPrefix("@") ? trimmed : "@\(trimmed)"
    }

    private var avatarSource: String {
        switch broadcast {
        case .scheduled(let b): return b.profileImageURL
        case .past(let p): return p.profileImageURL
        }
    }

    @ViewBuilder
    private var avatarImageView: some View {
        if let url = URL(string: avatarSource), url.scheme != nil {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    fallbackAvatarImage
                @unknown default:
                    fallbackAvatarImage
                }
            }
        } else {
            fallbackAvatarImage
        }
    }

    private var fallbackAvatarImage: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFill()
            .foregroundColor(.grayLight)
    }

    @ViewBuilder
    private var coverImageView: some View {
        if let url = URL(string: coverImage), url.scheme != nil {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholderCoverImage
                case .empty:
                    placeholderCoverImage
                @unknown default:
                    placeholderCoverImage
                }
            }
        } else {
            fallbackCoverImage
        }
    }

    private var fallbackCoverImage: some View {
        if UIImage(named: coverImage) != nil {
            Image(coverImage)
                .resizable()
                .scaledToFill()
        } else {
            Image("onboarding1")
                .resizable()
                .scaledToFill()
        }
    }

    private var placeholderCoverImage: some View {
        ZStack {
            Color(red: 0.12, green: 0.12, blue: 0.12)
            Image(systemName: "photo")
                .font(.system(size: 34, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
        }
    }

    private var imageFadeMask: some View {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black.opacity(0.8), location: 0.6),
                .init(color: .clear, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
