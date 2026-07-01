import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    
    // Hangi sekmenin seçili olduğunu tutan durum.
    enum ProfileTab {
        case scheduled, past
    }
    
    @Published var selectedTab: ProfileTab = .scheduled
    @Published var userProfile: UserProfile? = .placeholder
    @Published var pastBroadcasts: [PastBroadcast] = []
    @Published var scheduledBroadcasts: [ScheduledBroadcast] = []
    @Published var userID = ""
    @Published var shareURL: URL? = nil
    @Published var showShareSheet = false

    func fetchShareURL(username: String) {
        Task {
            do {
                let response = try await UserService.shared.fetchUserShareURL(username: username)
                if let urlString = response.resolvedURL, let url = URL(string: urlString) {
                    self.shareURL = url
                    self.showShareSheet = true
                } else {
                    // Fallback: API URL'i direkt kullan
                    let fallback = AppConfig.apiBaseURL + "/user/share/\(username)"
                    self.shareURL = URL(string: fallback)
                    self.showShareSheet = true
                }
            } catch {
                print("DEBUG: Share URL alınamadı: \(error.localizedDescription)")
                // Fallback olarak yine de share sheet aç
                let fallback = AppConfig.apiBaseURL + "/user/share/\(username)"
                self.shareURL = URL(string: fallback)
                self.showShareSheet = true
            }
        }
    }

    func onAppear() async {
        await fetchData()
    }

    // /api/user/share/u/{username}
    

    func fetchBroadcasts() {
        // Broadcasts verileri şimdilik mock kalabilir veya başka endpointten çekilebilir
        self.pastBroadcasts = [
            .init(title: "Gündem Değerlendirmesi", date: "28.09.2024", duration: "21:30", imageURL: "onboarding1"),
            .init(title: "Yeni Sezon Analizi", date: "01.10.2024", duration: "22:00", imageURL: "onboarding3")
        ]
        
        self.scheduledBroadcasts = [
            .init(title: "Siyaset Meydanı", date: "24.09.2024", time: "43:12", imageURL: "onboarding1"),
            .init(title: "Teknoloji Sohbetleri", date: "22.09.2024", time: "58:01", imageURL: "onboarding2"),
            .init(title: "Haftalık Gündem", date: "17.09.2024", time: "33:45", imageURL: "onboarding3")
            
        ]
        
    }
    
    func fetchData() async {
        do {
            let response = try await AuthService.shared.getMe()
            let user = response.user
            
            guard let resolvedUserId = user.resolvedId, !resolvedUserId.isEmpty else {
                print("Profil kullanıcı ID bilgisi bulunamadı.")
                return
            }

            self.userID = resolvedUserId
            
            self.userProfile = UserProfile(
                id: resolvedUserId,
                name: user.fullName ?? "İsimsiz Kullanıcı",
                username: user.username ?? "user",
                bio: user.profile?.bio ?? "Henüz bir biyografi eklemedin.",
                streamCount: 0,
                followersCount: user.profile?.followers?.count ?? 0,
                followingCount: user.profile?.following?.count ?? 0,
                profileImageURL: user.profile?.avatar ?? "",
                email: user.email ?? ""
            )

            await fetchUserRooms(with: resolvedUserId)
            
        } catch {
            print("Profil verileri alınırken hata: \(error.localizedDescription)")
            // Hata durumunda mock veriye düşülebilir
        }
    }
    
    func fetchUserRooms(with id: String) async {
        
        do {
            let response = try await RoomService.shared.fetchRooms(forUserId: id)
            applyUserRooms(response.rooms)
            print("user rooms: \(response)")
            
        }
        catch {
            print(error.localizedDescription)
            
            
        }
    }

    private func applyUserRooms(_ rooms: [RoomResponse]) {
        scheduledBroadcasts = rooms
            .filter { $0.status == 0 || $0.status == 1 }
            .map { room in
                ScheduledBroadcast(
                    title: room.title,
                    date: formattedDate(from: room.date),
                    time: formattedTime(from: room.date),
                    imageURL: room.image?.isEmpty == false ? room.image! : "onboarding1"
                )
            }

        pastBroadcasts = rooms
            .filter { $0.status != 0 && $0.status != 1 }
            .map { room in
                PastBroadcast(
                    title: room.title,
                    date: formattedDate(from: room.date),
                    duration: formattedDuration(from: room.details),
                    imageURL: room.image?.isEmpty == false ? room.image! : "onboarding1"
                )
            }
        
        print("scheduled Broadcasts: \(scheduledBroadcasts)")
        print("past Broadcasts : \(pastBroadcasts)")

        
        if let profile = userProfile {
            userProfile = UserProfile(
                id: profile.id,
                name: profile.name,
                username: profile.username,
                bio: profile.bio,
                streamCount: rooms.count,
                followersCount: profile.followersCount,
                followingCount: profile.followingCount,
                profileImageURL: profile.profileImageURL,
                email: profile.email
            )
        }
    }

    private func formattedDate(from dateString: String?) -> String {
        guard let date = parsedDate(from: dateString) else {
            return "-"
        }

        return Self.dateFormatter.string(from: date)
    }

    private func formattedTime(from dateString: String?) -> String {
        guard let date = parsedDate(from: dateString) else {
            return "-"
        }

        return Self.timeFormatter.string(from: date)
    }

    private func formattedDuration(from details: [RoomDetailResponse]?) -> String {
        guard let startDateString = details?.compactMap(\.startDate).first,
              let startDate = parsedDate(from: startDateString) else {
            return "-"
        }

        let seconds = max(Int(Date().timeIntervalSince(startDate)), 0)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func parsedDate(from dateString: String?) -> Date? {
        guard let dateString else { return nil }

        return Self.iso8601WithFractionalSecondsFormatter.date(from: dateString)
            ?? Self.iso8601Formatter.date(from: dateString)
    }

    private static let iso8601WithFractionalSecondsFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
}
