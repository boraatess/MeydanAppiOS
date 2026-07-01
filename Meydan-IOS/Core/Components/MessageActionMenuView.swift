import SwiftUI

struct MessageActionMenuView: View {
    @ObservedObject var viewModel: ChatViewModel
    let currentUserRole: AuthorRole
    
    var body: some View {
        if let _ = viewModel.selectedMessage {
            VStack(spacing: 0) {
                if currentUserRole == .moderator || currentUserRole == .chatOwner {
                    // Moderatör / Yayın Sahibi Menüsü
                    MessageActionButton(iconName: "xmark.circle", text: "Yayından Çıkar") {
                        viewModel.dismissMessageActions()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.showKickAlert = true
                        }
                    }
                    Divider().background(Color.white.opacity(0.1))
                    MessageActionButton(iconName: "exclamationmark.circle", text: "Şikayet Et") {
                        viewModel.reportMessage(viewModel.selectedMessage!)
                    }
                    Divider().background(Color.white.opacity(0.1))
                    MessageActionButton(iconName: "shield", text: "Engelle") {
                        viewModel.dismissMessageActions()
                    }
                } else {
                    // Normal Kullanıcı Menüsü
                    MessageActionButton(iconName: "exclamationmark.circle", text: "Şikayet Et") {
                        viewModel.reportMessage(viewModel.selectedMessage!)
                    }
                    Divider().background(Color.white.opacity(0.1))
                    MessageActionButton(iconName: "shield", text: "Engelle") {
                        viewModel.dismissMessageActions()
                    }
                }
            }
            .frame(width: 220)
            .background(Color(hex: "#1B1B1B"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }
}

struct MessageActionButton: View {
    let iconName: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Spacer()
                Image(systemName: iconName)
                    .font(.system(size: 18))
                
                Text(text)
                    .font(.manrope(.medium, size: 14))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
    }
}
