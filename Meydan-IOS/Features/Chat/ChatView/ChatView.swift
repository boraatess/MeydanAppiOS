import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var interstitialAdManager = ChatInterstitialAdManager()
    @State private var didRequestEntryAd = false
    
    @State private var navigationPath = NavigationPath()
    
    // Seçilen mesaj balonunun ekrandaki konumunu tutacak state
    @State private var selectedMessageFrame: CGRect = .zero
    
    // Projenin ilerleyen aşamalarında bu bilgi giriş yapan kullanıcıdan gelecektir.
    @State private var currentUserRole: AuthorRole = .chatOwner
    @Environment(\.dismiss) private var dismiss
    
    private let menuWidth: CGFloat = 220
    
    var body: some View {
        ZStack {
            // Arka plan rengini tüm ekrana yayıyoruz
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomChatHeaderView(
                    onBackTapped: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            viewModel.showExitConfirmation = true
                        }
                    },
                    onMoreButtonTapped: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            viewModel.showMoreOptionsMenu.toggle()
                        }
                    }
                )

                AdMobCompactBannerView(adUnitID: AdMobConfig.chatBannerAdUnitID)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                
                if viewModel.pollState != .none {
                    pollNotificationBar
                }
                
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        messageScrollView
                        
                        messageInputView
                            .padding(.horizontal, 16)
                    }
                    
                    // Options menüsü arkasını karartma kaplı overlay
                    if viewModel.showMoreOptionsMenu {
                        Color.black.opacity(0.55)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    viewModel.showMoreOptionsMenu = false
                                }
                            }
                            .transition(.opacity)
                    }
                    
                    // Options menüsü yukarıdan aşağı kayarak açılır
                    if viewModel.showMoreOptionsMenu {
                        ChatRoomOptionsMenuView(viewModel: viewModel)
                            .padding(.horizontal, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(10)
                    }
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .overlay(menuOverlay)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.showMessageActions)
        .onAppear {
            viewModel.connectToWebSocket()

            guard !didRequestEntryAd else { return }
            didRequestEntryAd = true
            interstitialAdManager.present()
        }
        .onDisappear { viewModel.disconnectFromWebSocket() }
        .overlay(popupOverlay)
    }
    
    @ViewBuilder
    private var popupOverlay: some View {
        if viewModel.showInviteSheet || viewModel.showParticipantsSheet || viewModel.showCreatePollSheet || viewModel.showPollVoteSheet || viewModel.showPollResultsSheet || viewModel.showReportSheet || viewModel.showExitConfirmation || viewModel.showKickAlert {
            ZStack {
                // Dimming Background
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            viewModel.showInviteSheet = false
                            viewModel.showParticipantsSheet = false
                            viewModel.showCreatePollSheet = false
                            viewModel.showPollVoteSheet = false
                            viewModel.showPollResultsSheet = false
                            viewModel.showReportSheet = false
                            viewModel.showExitConfirmation = false
                            // KickAlert tapa ile kapatılmasın (yalnızca buton ile)
                        }
                    }
                // Top Popups
                if viewModel.showInviteSheet || viewModel.showParticipantsSheet || viewModel.showCreatePollSheet || viewModel.showPollVoteSheet || viewModel.showPollResultsSheet || viewModel.showReportSheet {
                    VStack {
                        Group {
                            if viewModel.showInviteSheet {
                                InviteView(viewModel: viewModel)
                            } else if viewModel.showParticipantsSheet {
                                ParticipantsView(viewModel: viewModel)
                            } else if viewModel.showCreatePollSheet {
                                CreatePollView(viewModel: viewModel)
                            } else if viewModel.showPollVoteSheet {
                                PollVoteView(viewModel: viewModel)
                            } else if viewModel.showPollResultsSheet {
                                PollResultsView(viewModel: viewModel)
                            } else if viewModel.showReportSheet {
                                if viewModel.reportIsStream {
                                    ReportView(viewModel: ReportViewModel(context: .stream(roomId: viewModel.roomId, ownerUsername: viewModel.roomOwnerUsername, streamTitle: viewModel.roomTitle)), onDismiss: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            viewModel.showReportSheet = false
                                        }
                                    })
                                } else {
                                    ReportView(viewModel: ReportViewModel(context: .user(userId: viewModel.reportUserId ?? "", username: viewModel.reportUserName ?? "bilinmeyen")), onDismiss: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            viewModel.showReportSheet = false
                                        }
                                    })
                                }
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, topPopupOffset)
                        
                        Spacer()
                    }
                }
                // Centered Popups
                if viewModel.showExitConfirmation {
                    exitConfirmationPopup
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
                if viewModel.showKickAlert {
                    kickAlertView
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }
            .zIndex(100)
        }
    }

    private var topPopupOffset: CGFloat {
        viewModel.showPollVoteSheet ? 178 : 60
    }
    
    @ViewBuilder
    private var exitConfirmationPopup: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        viewModel.showExitConfirmation = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            Text("Sohbetten çıkmak istediğinize\nemin misiniz?")
                .font(.manrope(.bold, size: 20))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        viewModel.showExitConfirmation = false
                    }
                }) {
                    Text("Hayır")
                        .font(.manrope(.bold, size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "#363636"))
                        .cornerRadius(16)
                }
                Button(action: {
                    leaveChat()
                }) {
                    Text("Evet")
                        .font(.manrope(.bold, size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "#FF5C5C"))
                        .cornerRadius(16)
                }
            }
        }
        .padding(24)
        .background(Color(hex: "#1B1B1B"))
        .cornerRadius(24)
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var kickAlertView: some View {
        VStack(spacing: 20) {
            // Warning icon
            ZStack {
                Image("error")
                    .font(.system(size: 24, weight: .bold))
            }
            
            // Title
            Text("Bu Sohbetten Çıkarıldınız")
                .font(.manrope(.bold, size: 20))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Description
            VStack(spacing: 12) {
                Text("Moderatör tarafından sohbetten çıkarıldığınız için artık sohbeti görüntüleyemez ve sohbete katılamazsınız.")
                    .font(.manrope(.regular, size: 14))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text("Ana sayfaya dönerek diğer sohbetleri keşfedebilirsiniz.")
                    .font(.manrope(.regular, size: 14))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Ana Sayfaya Dön button
            Button(action: {
                leaveChat()
            }) {
                Text("Ana Sayfaya Dön")
                    .font(.manrope(.bold, size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#FF6B5B"), Color(hex: "#FF4040")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
            }
            .padding(.top, 4)
        }
        .padding(28)
        .background(Color(hex: "#1B1B1B"))
        .cornerRadius(24)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Subviews

    @ViewBuilder
    private var menuOverlay: some View {
        if viewModel.showMessageActions {
            // Arka plana dokunulduğunda menüyü kapatmak için yarı görünmez bir katman
            Color.black.opacity(0.01)
                .ignoresSafeArea()
                .onTapGesture { viewModel.dismissMessageActions() }

            if let selectedMessage = viewModel.selectedMessage {
                MessageActionMenuView(viewModel: viewModel, currentUserRole: currentUserRole)
                    .frame(width: menuWidth)
                    .position(
                        x: calculateMenuPosition(for: selectedMessageFrame, isMyMessage: selectedMessage.isSentByUser).x,
                        y: calculateMenuPosition(for: selectedMessageFrame, isMyMessage: selectedMessage.isSentByUser).y
                    )
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
    }
    
    @ViewBuilder
    private var pollNotificationBar: some View {
        Button(action: {
            if viewModel.pollState == .active {
                viewModel.showPollVoteSheet = true
            } else if viewModel.pollState == .ended {
                viewModel.showPollResultsSheet = true
            }
        }) {
            Group {
                if viewModel.pollState == .active {
                    HStack(spacing: 12) {
                        Text(pollNotificationTitle)
                            .font(.manrope(.medium, size: 18))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Spacer()

                        Image(systemName: "checklist")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 34)
                } else {
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Color(red: 0.20, green: 0.72, blue: 0.35))

                        Text("Anket Sonuçlandı")
                            .font(.manrope(.medium, size: 18))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(red: 0.60, green: 0.22, blue: 0.20))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 46)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var pollNotificationTitle: String {
        if viewModel.pollState == .active {
            let question = viewModel.activePollQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedQuestion = question.hasSuffix("?") ? question : "\(question)?"
            return "\(normalizedQuestion) Ankete Katıl!"
        }

        return "Anket Sonuçlandı"
    }
    
    private var messageScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(
                            message: message,
                            isSelected: viewModel.selectedMessage?.id == message.id
                        )
                        .id(message.id)
                        .onLongPressGesture {
                            viewModel.handleLongPress(on: message)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onPreferenceChange(MessageBubblePreferenceKey.self) { newFrame in
                if newFrame != .zero {
                    self.selectedMessageFrame = newFrame
                }
            }
            .onChange(of: viewModel.messages) { newMessages in
                if let lastMessage = newMessages.last {
                    withAnimation(.spring()) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var messageInputView: some View {
        HStack(spacing: 12) {
            // Artı butonu (Ekle)
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    viewModel.showAttachmentMenu.toggle()
                }
            }) {
                Image("sentiment_satisfied")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            // Metin alanı
            TextField("Sohbet Et", text: $viewModel.currentMessageText)
                .font(.manrope(.medium, size: 14))
                .foregroundColor(.white)
                .accentColor(.branding)
                .onChange(of: viewModel.currentMessageText) { newValue in
                    viewModel.handleTextChange(newValue)
                }
            
            Spacer()
            
            // Gönder butonu
            Button(action: viewModel.sendMessage) {
                Image("Send")
                    .renderingMode(.template)
                    .foregroundColor(viewModel.currentMessageText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .white)
                    .font(.system(size: 18))
            }
            .foregroundStyle(.white)
            .disabled(viewModel.currentMessageText.trimmingCharacters(in: .whitespaces).isEmpty)
            .animation(.easeInOut, value: viewModel.currentMessageText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 54/255, green: 54/255, blue: 54/255, opacity: 1))
        .cornerRadius(16, corners: .allCorners)
        .overlay(alignment: .bottomLeading) {
            if viewModel.showAttachmentMenu {
                attachmentMenuView
                    .offset(y: -70)
            }
            
            if viewModel.showMentionList {
                mentionListView
                    .offset(y: -220)
            }
        }
    }

    @ViewBuilder
    private var mentionListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Katılımcılar")
                .font(.manrope(.bold, size: 12))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.filteredUsers, id: \.self) { username in
                        Button(action: {
                            viewModel.selectMention(username: username)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.gray)
                                
                                Text("@\(username)")
                                    .font(.manrope(.medium, size: 14))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.001))
                        }
                        .buttonStyle(.plain)
                        
                        Divider().background(Color.white.opacity(0.1))
                    }
                }
            }
            .frame(height: 180)
        }
        .frame(width: 260)
        .background(Color(hex: "#1B1B1B"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    @ViewBuilder
    private var attachmentMenuView: some View {
        VStack(spacing: 12) {
            AttachmentOption(icon: "person.2.fill", title: "Katılımcılar") {
                viewModel.showAttachmentMenu = false
                viewModel.showParticipantsSheet = true
            }
            AttachmentOption(icon: "chart.bar.fill", title: "Anket Oluştur") {
                viewModel.showAttachmentMenu = false
                viewModel.showCreatePollSheet = true
            }
            AttachmentOption(icon: "person.badge.plus", title: "Davet Et") {
                viewModel.showAttachmentMenu = false
                viewModel.showInviteSheet = true
            }
        }
        .padding(12)
        .background(Color(hex: "#1B1B1B"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    private func AttachmentOption(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 30)
                
                Text(title)
                    .font(.manrope(.medium, size: 14))
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
    }

    private func leaveChat() {
        viewModel.showExitConfirmation = false
        interstitialAdManager.present {
            dismiss()
        }
    }
}

// MARK: - Custom Header View
struct CustomChatHeaderView: View {
    var onBackTapped: () -> Void
    var onMoreButtonTapped: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            // Asıl header
            HStack(spacing: 12) {
                Button(action: onBackTapped) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Türkiye - İspanya Maçı")
                        .font(.poppins(.semiBold, size: 15))
                        .foregroundColor(.white)
                    
                    Text("@cicekece")
                        .font(.poppins(.regular, size: 12))
                        .foregroundColor(.white.opacity(0.75))
                }
                
                Spacer()
                
                Button(action: onMoreButtonTapped) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(90))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "#FC6256"),
                    Color(hex: "#8B362F")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        
    }
    
}

/*  // Sadece alt köşeleri yuvarlak göstererek header'a yapışık görünüm
 .clipShape(
     UnevenRoundedRectangle(
         topLeadingRadius: 0,
         bottomLeadingRadius: 20,
         bottomTrailingRadius: 20,
         topTrailingRadius: 0
     )
 )
 
 */

// MARK: - Message Bubble View

struct MessageBubble: View {
    let message: Message
    var isSelected: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isSentByUser {
                // Diğer kullanıcıların avatarı
                if let avatarURL = message.authorAvatar, let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                }
            } else {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isSentByUser ? .trailing : .leading, spacing: 4) {
                // Başka kişinin mesajındaki @ isim
                if !message.isSentByUser, let author = message.authorName {
                    HStack(spacing: 4) {
                        
                        if message.authorRole == .chatOwner {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
                        }
                        
                        Text("@\(author.lowercased().replacingOccurrences(of: " ", with: ""))")
                            .font(.poppins(.semiBold, size: 11))
                            .foregroundColor(Color.branding)
                    }
                    .padding(.leading, 4)
                }
                
                Text(message.text)
                    .font(.manrope(.medium, size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isSentByUser
                        ? Color(hex: "#2C2D2F")
                        : Color(hex: "#1B1B1B")
                    )
                    .cornerRadius(18, corners: message.isSentByUser
                        ? [.topLeft, .bottomRight, .bottomLeft]
                        : [.bottomLeft, .topRight, .bottomRight])
            }
            .background {
                GeometryReader { geometry in
                    if isSelected {
                        Color.clear
                            .preference(key: MessageBubblePreferenceKey.self, value: geometry.frame(in: .global))
                    }
                }
            }
            
            if !message.isSentByUser {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Helpers

// Seçilen mesaj balonunun ekran koordinatlarını (CGRect) yukarı taşımak için kullanılır.
struct MessageBubblePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        // Sadece seçili olan balonun geçerli (sıfır olmayan) çerçevesini alıyoruz.
        if nextValue() != .zero {
            value = nextValue()
        }
    }
}

private extension ChatView {
    
    func getSafeAreaInsets() -> UIEdgeInsets {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first(where: { $0.isKeyWindow }) else {
                return .zero
            }
            return window.safeAreaInsets
        }

        func calculateMenuPosition(for frame: CGRect, isMyMessage: Bool) -> CGPoint {
            let screenWidth = UIScreen.main.bounds.width
            let safeArea = getSafeAreaInsets()
            
            let leadingMargin = safeArea.left + 16
            let trailingMargin = screenWidth - safeArea.right - 16
            
            // --- X Koordinatı Hesaplaması ---
            var x: CGFloat
            if isMyMessage {
                // Benim mesajımsa: Menünün sağını, balonun sağına hizala
                x = frame.maxX - (menuWidth / 2)
                // Sağdan taşmayı engelle
                if x + (menuWidth / 2) > trailingMargin {
                    x = trailingMargin - (menuWidth / 2)
                }
            } else {
                // Başkasının mesajıysa: Menünün solunu, balonun soluna hizala
                x = frame.minX + (menuWidth / 2)
                // Soldan taşmayı engelle
                if x - (menuWidth / 2) < leadingMargin {
                    x = leadingMargin + (menuWidth / 2)
                }
            }
            
            let menuHeight: CGFloat = 250 // Bu, menünün yaklaşık yüksekliğidir.
            let topSafeArea = safeArea.top
            
            // Menüyü balonun üstüne yerleştirmeyi hedefler
            var y = frame.minY - (menuHeight / 2) - 10
            
            // Eğer üstte yeterli yer yoksa (veya status bar'a çok yakınsa), alta yerleştirir
            if y - (menuHeight / 2) < topSafeArea {
                y = frame.maxY + (menuHeight / 2) + 10
            }
            
            return CGPoint(x: x, y: y)
        }
}

// MARK: - Preview

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatView()
                .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}
