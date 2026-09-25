import Foundation
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth

@MainActor
class ChatViewModel: ObservableObject {
    // list of messages
    @Published var messages: [Message] = []
    // current message text in the text field
    @Published var currentMessageText: String = ""
    @Published var messageValidationError: String?
    @Published var pollValidationError: String?

    // RTDB properties
    private var messagesHandle: DatabaseHandle?
    private var roomStatusHandle: DatabaseHandle?
    private var connectionTask: Task<Void, Never>?
    @Published var joinRoomError: String?
    @Published private(set) var isJoiningRoom = false
    @Published private(set) var isJoinedToRoom = false
    private var currentUserId = ""
    @Published private var currentUsername = ""
    private var currentUserAvatar: String?
    private var isLoadingCurrentUser = false
    private var hasJoinedRoomViewers = false
    private var hasLeftRoomViewers = false
    private var isLeavingRoomViewers = false
    private var hasScheduledRoomClosure = false
    let roomId: String

    private var dbRef: DatabaseReference? {
        guard !RuntimeEnvironment.isSwiftUIPreview,
              FirebaseApp.app() != nil else {
            return nil
        }

        return Database.database().reference()
    }
    
    // Basılı tutularak seçilen mesajı saklar.
    @Published var selectedMessage: Message?
    
    // Mesajlara basılı tutunca açılan aksiyon menüsünün görünürlüğünü kontrol eder.
    @Published var showMessageActions = false
    
    // Sağ üstteki "Daha Fazla" menüsünün görünürlüğünü kontrol eder.
    @Published var showMoreOptionsMenu = false
    
    // "Davet Et" ekranının (sheet) gösterilip gösterilmeyeceğini belirler.
    @Published var showInviteSheet = false
    @Published var isInvitingUser = false
    @Published var inviteErrorMessage: String?
    @Published var inviteSuccessMessage: String?
    @Published var shareURL: URL?
    @Published var showShareSheet = false
    
    // "Katılımcıları Gör" ekranının gösterilip gösterilmeyeceğini belirler.
    @Published var showParticipantsSheet = false
    @Published var participants: [Participant] = []
    @Published var isLoadingParticipants = false
    @Published var participantsErrorMessage: String?
    
    // "Anket Oluştur" ekranının gösterilip gösterilmeyeceğini belirler.
    @Published var showCreatePollSheet = false

    // MARK: - Poll Properties
    enum PollState {
        case none
        case active
        case ended
    }
    
    @Published var pollState: PollState = .none
    @Published var activePollQuestion: String = ""
    @Published var activePollOptions: [String] = []
    @Published var pollVotes: [Int: Int] = [:] // Option index -> Vote count
    @Published var showPollVoteSheet = false
    @Published var showPollResultsSheet = false

    @Published var showReportSheet = false
    @Published var reportIsStream: Bool = false
    @Published var reportUserName: String? = nil
    @Published var reportUserId: String? = nil
    
    // Çıkış onayı popup'ının görünürlüğünü kontrol eder.
    @Published var showExitConfirmation = false
    @Published var isEndingRoom = false
    @Published var roomActionError: String?
    @Published var roomActionSuccess: String?
    @Published private(set) var isBanningUser = false
    
    // Yayından çıkarılma alert'inin görünürlüğünü kontrol eder.
    @Published var showKickAlert = false

    // Oda sonlandığında kullanıcıya gösterilecek bilgilendirme ekranı.
    @Published var showRoomEndedInfo = false
    @Published var isRoomClosing = false
    @Published var closingCountdownText: String?
    @Published var roomClosedByUsername: String?

    private var closingCountdownTimer: Timer?
    
    // MARK: - Poll Actions
    @discardableResult
    func startPoll(question: String, options: [String]) -> Bool {
        pollValidationError = ([question] + options).compactMap { ContentFilter.warning(for: $0) }.first
        guard pollValidationError == nil else { return false }
        let filteredOptions = options.filter { !$0.isEmpty }
        self.activePollQuestion = question
        self.activePollOptions = filteredOptions
        self.pollVotes = [:]
        for i in 0..<activePollOptions.count {
            pollVotes[i] = Int.random(in: 1...50) // Mock initial votes
        }
        self.pollState = .active
        self.showCreatePollSheet = false
        
        Task {
            do {
                let request = CreatePollRequest(
                    roomId: roomId,
                    question: question,
                    options: filteredOptions
                )
                let response = try await RoomService.shared.createPoll(request: request)
                print("DEBUG: Poll created successfully. Response status: \(response.status ?? ""), message: \(response.message ?? "")")
            } catch {
                print("DEBUG: Failed to create poll via API: \(error.localizedDescription)")
            }
        }
        return true
    }
    
    func vote(optionIndex: Int) {
        pollVotes[optionIndex, default: 0] += 1
        self.showPollVoteSheet = false
        
        Task {
            do {
                let request = VotePollRequest(
                    roomId: roomId,
                    optionId: optionIndex
                )
                let response = try await RoomService.shared.votePoll(request: request)
                print("DEBUG: Vote submitted successfully. Response status: \(response.status ?? ""), message: \(response.message ?? "")")
            } catch {
                print("DEBUG: Failed to submit vote via API: \(error.localizedDescription)")
            }
        }
    }

    func endPoll() {
        guard pollState == .active else { return }
        pollState = .ended
        showCreatePollSheet = false
        showPollVoteSheet = false
        showPollResultsSheet = true
    }
    
    func getTotalVotes() -> Int {
        pollVotes.values.reduce(0, +)
    }
    
    func getPercentage(for index: Int) -> Int {
        let total = getTotalVotes()
        guard total > 0 else { return 0 }
        return Int(Double(pollVotes[index, default: 0]) / Double(total) * 100)
    }
    // Chat odasına ait bilgiler (başlık ve sahibi), header ile uyumlu tutulur
    let roomTitle: String
    let roomOwnerUsername: String
    let roomOwnerUserId: String

    var isCurrentUserRoomOwner: Bool {
        !currentUserId.isEmpty
            && !roomOwnerUserId.isEmpty
            && currentUserId == roomOwnerUserId
    }

    private var hasValidRoomId: Bool {
        !roomId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var exitConfirmationMessage: String {
        isCurrentUserRoomOwner
            ? "Odayı sonlandırmak istediğinizden\nemin misiniz?"
            : "Sohbetten çıkmak istediğinize\nemin misiniz?"
    }
    
    init(
        roomId: String = "test_room_123",
        roomTitle: String = "Türkiye - İspanya Maçı",
        roomOwnerUsername: String = "rumeysasacak",
        roomOwnerUserId: String = ""
    ) {
        self.roomId = roomId
        self.roomTitle = roomTitle
        self.roomOwnerUsername = roomOwnerUsername
        self.roomOwnerUserId = roomOwnerUserId
        // loadMockMessages()
    }

    func handleBackTapped() {
        Task {
            await loadCurrentUserIfNeeded()
            showExitConfirmation = true
        }
    }

    func endRoomIfNeededBeforeExit() async -> Bool {
        guard !isEndingRoom else { return false }
        roomActionError = nil

        isEndingRoom = true
        defer { isEndingRoom = false }

        await loadCurrentUserIfNeeded()
        guard hasValidRoomId else {
            roomActionError = "Oda bilgisi bulunamadı."
            return false
        }

        guard !currentUserId.isEmpty else {
            roomActionError = "Kullanıcı bilgileriniz doğrulanamadı. Lütfen tekrar deneyin."
            return false
        }
        if isCurrentUserRoomOwner && !showRoomEndedInfo && !hasScheduledRoomClosure {
            do {
                _ = try await RoomService.shared.scheduleRoomClosure(id: roomId)
                hasScheduledRoomClosure = true
            } catch {
                roomActionError = error.localizedDescription
                return false
            }
        }

        return await leaveRoomViewersIfNeeded(reason: "confirmed_exit")
    }
    
    func connectToWebSocket() {
        print("RTDB listener başlatılıyor...")
        guard hasValidRoomId else {
            print("DEBUG: Chat bağlantısı başlatılmadı; roomId boş. roomId=\(roomId)")
            return
        }

        guard !RuntimeEnvironment.isSwiftUIPreview,
              FirebaseApp.app() != nil else {
            print("DEBUG: Firebase yapılandırılmadığı için RTDB listener başlatılmadı.")
            return
        }

        print("DEBUG: Firebase Auth current uid: \(Auth.auth().currentUser?.uid ?? "nil")")
        guard dbRef != nil else {
            print("DEBUG: Firebase RTDB reference oluşturulamadı.")
            return
        }

        guard connectionTask == nil, !isJoinedToRoom else { return }
        joinRoomError = nil
        connectionTask = Task {
            defer { connectionTask = nil }
            await loadCurrentUserIfNeeded()
            guard !Task.isCancelled else { return }
            // Keep status updates available even if the join request is rejected for a closed room.
            if roomStatusHandle == nil { listenForRoomStatus() }
            guard await joinRoomViewers(), !Task.isCancelled else { return }
            if messagesHandle == nil { listenForMessages() }
        }
    }

    private func joinRoomViewers() async -> Bool {
        guard hasValidRoomId else {
            joinRoomError = "Oda bilgisi bulunamadı."
            return false
        }

        isJoiningRoom = true
        defer { isJoiningRoom = false }
        do {
            print("DEBUG: join-room-viewers çağrılıyor. roomId=\(roomId)")
            _ = try await RoomService.shared.joinRoomViewers(id: roomId)
            hasJoinedRoomViewers = true
            hasLeftRoomViewers = false
            isJoinedToRoom = true
            if Task.isCancelled {
                await leaveRoomViewersIfNeeded(reason: "cancelled_join")
                return false
            }
            return true
        } catch {
            if !Task.isCancelled && !showRoomEndedInfo { joinRoomError = error.localizedDescription }
            return false
        }
    }

    @discardableResult
    func leaveRoomViewersIfNeeded(reason: String) async -> Bool {
        guard hasValidRoomId else {
            roomActionError = "Oda bilgisi bulunamadı."
            return false
        }

        guard hasJoinedRoomViewers, !hasLeftRoomViewers else { return true }
        guard !isLeavingRoomViewers else { return false }
        isLeavingRoomViewers = true
        defer { isLeavingRoomViewers = false }

        do {
            print("DEBUG: leave-room-viewers çağrılıyor. reason=\(reason), roomId=\(roomId), joined=\(hasJoinedRoomViewers)")
            _ = try await RoomService.shared.leaveRoomViewers(id: roomId)
            hasLeftRoomViewers = true
            hasJoinedRoomViewers = false
            isJoinedToRoom = false
            return true
        } catch {
            roomActionError = error.localizedDescription
            return false
        }
    }
    
    func disconnectFromWebSocket() {
        print("RTDB listener kapatılıyor...")
        connectionTask?.cancel()
        isJoinedToRoom = false
        guard let dbRef else { return }

        if let handle = messagesHandle {
            dbRef.child("rooms").child(roomId).child("messages").removeObserver(withHandle: handle)
        }
        if let handle = roomStatusHandle {
            dbRef.child("rooms").child(roomId).child("status").removeObserver(withHandle: handle)
        }

        messagesHandle = nil
        roomStatusHandle = nil
        stopClosingCountdown()
    }
    
    private func listenForMessages() {
        guard let dbRef, hasValidRoomId else { return }

        let roomMessagesRef = dbRef.child("rooms").child(roomId).child("messages")
        
        messagesHandle = roomMessagesRef.queryOrdered(byChild: "createdAt").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            
            var newMessages: [Message] = []
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let dict = childSnapshot.value as? [String: Any] {
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dict)
                        var message = try JSONDecoder().decode(Message.self, from: jsonData)
                        message.id = childSnapshot.key // RTDB auto-id'sini atıyoruz
                        message.isCurrentUser = !self.currentUserId.isEmpty
                            && message.senderId == self.currentUserId
                        newMessages.append(message)
                    } catch {
                        print("Mesaj çözümlenemedi: \(error)")
                    }
                }
            }
            
            self.messages = newMessages
        }
        
    }

    private func listenForRoomStatus() {
        guard let dbRef, hasValidRoomId else { return }

        roomStatusHandle = dbRef.child("rooms").child(roomId).child("status").observe(.value) { [weak self] snapshot in
            guard let self else { return }

            if let status = snapshot.value as? String {
                self.handleRoomStatus(state: status, closeDeadline: nil, closedBy: nil)
            } else if let status = snapshot.value as? Int,
                      status == 2 || status == 3 {
                self.handleRoomStatus(state: "closed", closeDeadline: nil, closedBy: nil)
            } else if let dict = snapshot.value as? [String: Any] {
                let state = (dict["state"] as? String)
                    ?? (dict["status"] as? String)
                    ?? ""
                let closeDeadline = (dict["closeDeadline"] as? TimeInterval)
                    ?? (dict["closeDeadline"] as? NSNumber)?.doubleValue
                    ?? (dict["deadline"] as? TimeInterval)
                    ?? (dict["deadline"] as? NSNumber)?.doubleValue
                let closedBy = (dict["closedBy"] as? String)
                    ?? (dict["closedByUsername"] as? String)
                    ?? (dict["hostUsername"] as? String)

                self.handleRoomStatus(state: state, closeDeadline: closeDeadline, closedBy: closedBy)
            }
        }
    }

    private func handleRoomStatus(state: String, closeDeadline: TimeInterval?, closedBy: String?) {
        switch state.lowercased() {
        case "closing":
            showRoomEndedInfo = false
            roomClosedByUsername = closedBy
            isRoomClosing = true
            startClosingCountdown(deadlineMillis: closeDeadline)
        case "active":
            hasScheduledRoomClosure = false
            showRoomEndedInfo = false
            isRoomClosing = false
            roomClosedByUsername = nil
            stopClosingCountdown()
        case "closed", "ended", "finished":
            roomClosedByUsername = closedBy
            isRoomClosing = false
            stopClosingCountdown()
            showRoomEndedInfoIfNeeded()
        default:
            break
        }
    }

    private func startClosingCountdown(deadlineMillis: TimeInterval?) {
        stopClosingCountdown()
        updateClosingCountdown(deadlineMillis: deadlineMillis)

        guard let deadlineMillis else { return }
        closingCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateClosingCountdown(deadlineMillis: deadlineMillis)
            }
        }
    }

    private func updateClosingCountdown(deadlineMillis: TimeInterval?) {
        guard let deadlineMillis else {
            closingCountdownText = nil
            return
        }

        let remainingSeconds = max(Int(ceil((deadlineMillis - Date().timeIntervalSince1970 * 1000) / 1000)), 0)
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        closingCountdownText = String(format: "%02d:%02d", minutes, seconds)
    }

    private func stopClosingCountdown() {
        closingCountdownTimer?.invalidate()
        closingCountdownTimer = nil
        closingCountdownText = nil
    }

    private func showRoomEndedInfoIfNeeded() {
        joinRoomError = nil
        showInviteSheet = false
        showParticipantsSheet = false
        showCreatePollSheet = false
        showPollVoteSheet = false
        showPollResultsSheet = false
        showReportSheet = false
        showMoreOptionsMenu = false
        showExitConfirmation = false
        showRoomEndedInfo = true
    }
    
    // MARK: - User Actions
    
    func sendMessage() {
        let messageText = currentMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty, isJoinedToRoom, !showRoomEndedInfo else { return }
        messageValidationError = ContentFilter.warning(for: messageText)
        guard messageValidationError == nil else { return }
        currentMessageText = ""

        Task {
            await loadCurrentUserIfNeeded()
            persistMessage(text: messageText)
        }
    }

    private func persistMessage(text: String) {
        guard let dbRef else {
            print("DEBUG: Firebase yapılandırılmadığı için mesaj RTDB'ye yazılmadı.")
            return
        }

        guard hasValidRoomId else {
            print("DEBUG: Mesaj RTDB'ye yazılmadı; roomId boş. roomId=\(roomId)")
            return
        }
        
        // Şimdiki zamanı "HH:mm" formatında al
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTimeString = formatter.string(from: Date())
        
        let newMessage = Message(
            id: nil,
            text: text,
            senderId: currentUserId.isEmpty ? nil : currentUserId,
            username: currentUsername.isEmpty ? nil : currentUsername,
            authorName: currentUsername.isEmpty ? nil : currentUsername,
            authorAvatar: currentUserAvatar,
            authorRole: .user,
            timestamp: currentTimeString,
            createdAt: nil,
            isCurrentUser: true
        )
        
        do {
            let encodedData = try JSONEncoder().encode(newMessage)
            if var dict = try JSONSerialization.jsonObject(with: encodedData, options: []) as? [String: Any] {
                // Sunucu saatini ekle (ServerValue.timestamp())
                dict["createdAt"] = ServerValue.timestamp()
                
                // AutoID ile yeni mesaj düğümü oluştur ve veriyi bas
                let roomMessagesRef = dbRef.child("rooms").child(roomId).child("messages").childByAutoId()
                roomMessagesRef.setValue(dict)
            }
        } catch {
            print("Mesaj gönderilirken hata oluştu: \(error)")
        }
    }

    private func loadCurrentUserIfNeeded() async {
        guard currentUserId.isEmpty || currentUsername.isEmpty else { return }
        guard !isLoadingCurrentUser else { return }
        isLoadingCurrentUser = true
        defer { isLoadingCurrentUser = false }

        do {
            let response = try await AuthService.shared.getMe()
            currentUserId = response.user.resolvedId ?? ""
            currentUsername = response.user.username ?? ""
            currentUserAvatar = response.user.profile?.avatar
        } catch {
            print("DEBUG: Chat kullanıcı bilgisi alınamadı: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Message Actions
    
    func handleLongPress(on message: Message) {
        // Zaten bir menü açıksa, tekrar basıldığında kapat
        if showMessageActions && selectedMessage?.id == message.id {
            dismissMessageActions()
        } else {
            selectedMessage = message
            showMessageActions = true
        }
    }
    
    func dismissMessageActions() {
        showMessageActions = false
        // Animasyonun bitmesi için küçük bir gecikme sonrası modeli temizle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.selectedMessage = nil
        }
    }
    
    func reactToMessage(with emoji: String, to message: Message) {
        print("Reacting with \(emoji) to message: \(message.text)")
        dismissMessageActions()
    }
    
    // Menüdeki her bir eylem için fonksiyonlar (şimdilik print yapacaklar)
    func replyToMessage(_ message: Message) { print("Replying to: \(message.text)") }
    func copyMessage(_ message: Message) { print("Copied: \(message.text)") }
    func editMessage(_ message: Message) { print("Editing: \(message.text)") }
    func deleteMessage(_ message: Message) { print("Deleting: \(message.text)") }
    
    func reportMessage(_ message: Message) {
        print("Reporting: \(message.text)")
        // Kullanıcı şikayeti için sheet aç
        reportIsStream = false
        reportUserName = message.resolvedUsername ?? "Bilinmeyen"
        reportUserId = message.senderId
        // Menü overlay'ini kapatıp ardından sheet'i göster
        dismissMessageActions()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.showReportSheet = true
        }
    }
    func canBanUser(_ message: Message) -> Bool {
        guard isCurrentUserRoomOwner,
              let targetId = message.senderId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !targetId.isEmpty else { return false }
        return targetId != currentUserId && targetId != roomOwnerUserId && !message.isCurrentUser
    }

    func banUser(_ message: Message) async {
        guard !isBanningUser else { return }
        roomActionError = nil
        roomActionSuccess = nil
        guard canBanUser(message), hasValidRoomId, !showRoomEndedInfo,
              let targetId = message.senderId?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            roomActionError = "Bu kullanıcıyı odadan çıkaramazsınız. İşlemi yalnızca oda sahibi yapabilir."
            return
        }
        isBanningUser = true
        defer { isBanningUser = false }
        do {
            let response = try await RoomService.shared.banUser(
                request: BanRoomUserRequest(roomId: roomId, userIdToBan: targetId)
            )
            participants.removeAll { $0.userId == targetId }
            roomActionSuccess = response.message?.isEmpty == false
                ? response.message : "Kullanıcı odadan çıkarıldı ve odaya erişimi engellendi."
        } catch {
            roomActionError = error.localizedDescription
        }
    }

    func muteUser(author: String) { print("Muting user: \(author)") }
    
    func inviteUser(username: String) {
        guard !isInvitingUser else { return }
        let trimmedUsername = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        
        guard !trimmedUsername.isEmpty else {
            inviteErrorMessage = "Lütfen bir kullanıcı adı girin."
            inviteSuccessMessage = nil
            return
        }

        guard hasValidRoomId else {
            inviteErrorMessage = "Oda bilgisi bulunamadı."
            inviteSuccessMessage = nil
            print("DEBUG: Davet gönderilemedi; roomId boş. roomId=\(roomId)")
            return
        }
        
        isInvitingUser = true
        inviteErrorMessage = nil
        inviteSuccessMessage = nil
        
        Task {
            do {
                await loadCurrentUserIfNeeded()
                guard !currentUserId.isEmpty,
                      !currentUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    isInvitingUser = false
                    inviteErrorMessage = "Kullanıcı bilgileriniz doğrulanamadı. Lütfen tekrar deneyin."
                    return
                }
                guard !isCurrentUser(username: trimmedUsername) else {
                    isInvitingUser = false
                    inviteErrorMessage = "Kendinizi odaya davet edemezsiniz."
                    return
                }

                let request = RoomInviteRequest(roomId: roomId, username: trimmedUsername)
                print("DEBUG: Davet isteği gönderiliyor. roomId=\(roomId), username=\(trimmedUsername)")
                let response = try await RoomService.shared.inviteUser(request: request)
                isInvitingUser = false
                inviteSuccessMessage = response.message ?? "Davet gönderildi."
            } catch {
                isInvitingUser = false
                inviteErrorMessage = error.localizedDescription
            }
        }
    }
    
    func resetInviteState() {
        inviteErrorMessage = nil
        inviteSuccessMessage = nil
    }

    func isCurrentUser(username: String) -> Bool {
        let lhs = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
            .lowercased()
        let rhs = currentUsername
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
            .lowercased()
        return !lhs.isEmpty && !rhs.isEmpty && lhs == rhs
    }

    func shareRoom() {
        guard hasValidRoomId else {
            inviteErrorMessage = "Oda bilgisi bulunamadı."
            return
        }

        Task {
            do {
                let response = try await RoomService.shared.fetchRoomShareURL(id: roomId)
                if let urlString = response.resolvedURL, let url = URL(string: urlString) {
                    shareURL = url
                } else {
                    shareURL = URL(string: "\(AppConfig.apiBaseURL)/rooms/share/\(roomId)")
                }
            } catch {
                print("DEBUG: Chat oda paylaşım linki alınamadı: \(error.localizedDescription)")
                shareURL = URL(string: "\(AppConfig.apiBaseURL)/rooms/share/\(roomId)")
            }

            showShareSheet = shareURL != nil
        }
    }
    
    func loadParticipants() {
        isLoadingParticipants = true
        participantsErrorMessage = nil
        
        Task {
            do {
                let response = try await RoomService.shared.fetchRoomViewers(id: roomId)
                participants = response.viewers.map { viewer in
                    let resolvedUserId = viewer._id
                    let resolvedName: String
                    if !viewer.fullName.isEmpty {
                        resolvedName = viewer.fullName
                    } else if !viewer.username.isEmpty {
                        resolvedName = viewer.username
                    } else {
                        resolvedName = "Kullanıcı"
                    }
                    
                    return Participant(
                        id: resolvedUserId.isEmpty ? "\(viewer.username)-\(UUID().uuidString)" : resolvedUserId,
                        userId: resolvedUserId,
                        name: resolvedName,
                        username: viewer.username,
                        avatar: viewer.profileAvatar
                    )
                }
                isLoadingParticipants = false
            } catch {
                isLoadingParticipants = false
                participantsErrorMessage = error.localizedDescription
            }
        }
    }
    
    func resetParticipantsState() {
        participants = []
        participantsErrorMessage = nil
        isLoadingParticipants = false
    }
    
    func reportCurrentStream() {
        // Yayını şikayet etmek için sheet açılır
        reportIsStream = true
        // Eğer başka menüler açıksa kapat
        showMoreOptionsMenu = false
        // Küçük bir gecikme sonrası sheet'i göster
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showReportSheet = true
        }
    }
    
    // MARK: - Mentions
    @Published var filteredUsers: [String] = []
    @Published var showMentionList = false
    
    private let allParticipants = ["ahmetozturk", "asliyilmaz", "boraates", "cicekece", "rumeysasacak"]
    
    func handleTextChange(_ text: String) {
        if let lastWord = text.split(separator: " ").last, lastWord.hasPrefix("@") {
            let query = String(lastWord.dropFirst()).lowercased()
            if query.isEmpty {
                filteredUsers = allParticipants
            } else {
                filteredUsers = allParticipants.filter { $0.lowercased().contains(query) }
            }
            showMentionList = !filteredUsers.isEmpty
        } else {
            showMentionList = false
        }
    }
    
    func selectMention(username: String) {
        if let lastAtRange = currentMessageText.range(of: "@", options: .backwards) {
            let prefix = currentMessageText[..<lastAtRange.lowerBound]
            currentMessageText = String(prefix) + "@" + username + " "
        }
        showMentionList = false
    }
    
    // MARK: - Mock Data
    
    private func loadMockMessages() {
        self.messages = [
            Message(text: "Arda Güler harika oynuyor bu dünya kupasında.", authorName: "asliyilmaz", authorAvatar: "https://i.pravatar.cc/150?u=asli", authorRole: .user, timestamp: "19:31"),
            Message(text: "Sakatlanmaz umarım.", authorName: nil, authorAvatar: nil, authorRole: .moderator, timestamp: "19:31"),
            Message(text: "Harika bir şuttu direkten döndü.", authorName: "ahmetozturk", authorAvatar: "https://i.pravatar.cc/150?u=ahmet", authorRole: .user, timestamp: "19:32"),
            Message(text: "Harika bir şuttu direkten döndü.", authorName: nil, authorAvatar: nil, authorRole: .moderator, timestamp: "19:32"),
            Message(text: "Arda Güler harika oynuyor bu dünya kupasında.", authorName: "asliyilmaz", authorAvatar: "https://i.pravatar.cc/150?u=asli", authorRole: .user, timestamp: "19:33"),
            Message(text: "Hakem ofsayt kararı verdi.", authorName: "cicekece", authorAvatar: "", authorRole: .chatOwner, timestamp: "19:32"),
            Message(text: "Sakatlanmaz umarım.", authorName: "asliyilmaz", authorAvatar: "https://i.pravatar.cc/150?u=asli", authorRole: .user, timestamp: "19:33"),
            Message(text: "Buna nasıl kart çıkmaz?", authorName: nil, authorAvatar: nil, authorRole: .moderator, timestamp: "19:34"),
            Message(text: "Buna nasıl kart çıkmaz?", authorName: "asliyilmaz", authorAvatar: "https://i.pravatar.cc/150?u=asli", authorRole: .user, timestamp: "19:34"),
        ]
    }
}
