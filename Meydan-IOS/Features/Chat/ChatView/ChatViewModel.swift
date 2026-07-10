import Foundation
import FirebaseDatabase

@MainActor
class ChatViewModel: ObservableObject {
    // list of messages
    @Published var messages: [Message] = []
    // current message text in the text field
    @Published var currentMessageText: String = ""

    // RTDB properties
    private let dbRef = Database.database().reference()
    private var messagesHandle: DatabaseHandle?
    private var currentUserId = ""
    private var currentUsername = ""
    private var currentUserAvatar: String?
    private var isLoadingCurrentUser = false
    let roomId: String
    
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
    
    // "Katılımcıları Gör" ekranının gösterilip gösterilmeyeceğini belirler.
    @Published var showParticipantsSheet = false
    @Published var participants: [Participant] = []
    @Published var isLoadingParticipants = false
    @Published var participantsErrorMessage: String?
    
    // "Anket Oluştur" ekranının gösterilip gösterilmeyeceğini belirler.
    @Published var showCreatePollSheet = false

    // "Ekle" (+) menüsünün görünürlüğünü kontrol eder.
    @Published var showAttachmentMenu = false

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
    
    // Yayından çıkarılma alert'inin görünürlüğünü kontrol eder.
    @Published var showKickAlert = false
    
    // MARK: - Poll Actions
    func startPoll(question: String, options: [String]) {
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
    }
    
    func vote(optionIndex: Int) {
        pollVotes[optionIndex, default: 0] += 1
        self.showPollVoteSheet = false
        // For demo purposes, end the poll after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.pollState = .ended
        }
        
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
    
    init(
        roomId: String = "test_room_123",
        roomTitle: String = "Türkiye - İspanya Maçı",
        roomOwnerUsername: String = "rumeysasacak"
    ) {
        self.roomId = roomId
        self.roomTitle = roomTitle
        self.roomOwnerUsername = roomOwnerUsername
        loadMockMessages()
    }
    
    func connectToWebSocket() {
        print("RTDB listener başlatılıyor...")
        Task {
            await loadCurrentUserIfNeeded()
            listenForMessages()
        }
    }
    
    func disconnectFromWebSocket() {
        print("RTDB listener kapatılıyor...")
        if let handle = messagesHandle {
            dbRef.child("rooms").child(roomId).child("messages").removeObserver(withHandle: handle)
        }
    }
    
    private func listenForMessages() {
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
    
    // MARK: - User Actions
    
    func sendMessage() {
        let messageText = currentMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        currentMessageText = ""

        Task {
            await loadCurrentUserIfNeeded()
            persistMessage(text: messageText)
        }
    }

    private func persistMessage(text: String) {
        
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
        guard currentUserId.isEmpty, !isLoadingCurrentUser else { return }
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
    func muteUser(author: String) { print("Muting user: \(author)") }
    
    func inviteUser(username: String) {
        let trimmedUsername = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        
        guard !trimmedUsername.isEmpty else {
            inviteErrorMessage = "Lütfen bir kullanıcı adı girin."
            inviteSuccessMessage = nil
            return
        }
        
        isInvitingUser = true
        inviteErrorMessage = nil
        inviteSuccessMessage = nil
        
        Task {
            do {
                let request = RoomInviteRequest(roomId: roomId, username: trimmedUsername)
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
        isInvitingUser = false
    }
    
    func loadParticipants() {
        isLoadingParticipants = true
        participantsErrorMessage = nil
        
        Task {
            do {
                let response = try await RoomService.shared.fetchRoomViewers(id: roomId)
                participants = response.viewers.map { viewer in
                    let resolvedId = viewer._id.isEmpty ? viewer.username : viewer._id
                    let resolvedName: String
                    if !viewer.fullName.isEmpty {
                        resolvedName = viewer.fullName
                    } else if !viewer.username.isEmpty {
                        resolvedName = viewer.username
                    } else {
                        resolvedName = "Kullanıcı"
                    }
                    
                    return Participant(
                        id: resolvedId.isEmpty ? UUID().uuidString : resolvedId,
                        name: resolvedName,
                        username: viewer.username,
                        avatar: viewer.profile?.avatar
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
