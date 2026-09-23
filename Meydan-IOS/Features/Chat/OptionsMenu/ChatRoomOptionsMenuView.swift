import SwiftUI

struct ChatRoomOptionsMenuView: View {
    @ObservedObject var viewModel: ChatViewModel

    private var isModeratorView: Bool {
        viewModel.isCurrentUserRoomOwner
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Başlık + Kapat Butonu
            HStack {
                Text("Daha fazla bilgi")
                    .font(.manrope(.bold, size: 22))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        viewModel.showMoreOptionsMenu = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 12)
            
            // MARK: - Bilgi Metni
            Text(infoText)
                .font(.manrope(.regular, size: 16))
                .foregroundColor(.white.opacity(0.92))
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            
            // MARK: - Eylem Butonları
            VStack(spacing: 14) {
                if isModeratorView {
                    OptionsRow(iconName: "group_add", text: "Davet Et") {
                        closeMenuThen {
                            viewModel.showInviteSheet = true
                        }
                    }
                    OptionsRow(iconName: "group", text: "Katılımcıları Gör") {
                        closeMenuThen {
                            viewModel.showParticipantsSheet = true
                        }
                    }
                    if viewModel.pollState == .active {
                        OptionsRow(iconName: "stop.circle.fill", text: "Anketi Sonlandır", tint: Color(hex: "#FF5C5C")) {
                            closeMenuThen {
                                viewModel.endPoll()
                            }
                        }
                    } else {
                        OptionsRow(iconName: "checklist_rtl", text: "Anket Oluştur") {
                            closeMenuThen {
                                viewModel.showCreatePollSheet = true
                            }
                        }
                    }
                    OptionsRow(iconName: "ci_chat-circle-close", text: "Odayı Sonlandır") {
                        closeMenuThen {
                            viewModel.showExitConfirmation = true
                        }
                    }
                } else {
                    OptionsRow(iconName: "group_add", text: "Davet Et") {
                        closeMenuThen {
                            viewModel.showInviteSheet = true
                        }
                    }
                    OptionsRow(iconName: "group", text: "Katılımcıları Gör") {
                        closeMenuThen {
                            viewModel.showParticipantsSheet = true
                        }
                    }
                    OptionsRow(iconName: "errorWhite", text: "Yayını Şikayet Et") {
                        viewModel.reportCurrentStream()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(hex: "#1B1B1B"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
    }

    private var infoText: String {
        let owner = viewModel.roomOwnerUsername.hasPrefix("@")
            ? viewModel.roomOwnerUsername
            : "@\(viewModel.roomOwnerUsername)"

        if isModeratorView {
            return "21.09.25 - 19.30 tarihinde \(owner)\ntarafından planlandı.\nSohbet spor alanı hakkında."
        }

        return "21.09.25 - 19.30 tarihinde \(owner)\ntarafından planlandı.\nSohbet spor alanı hakkında."
    }

    private func closeMenuThen(_ action: @escaping () -> Void) {
        viewModel.showMoreOptionsMenu = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            action()
        }
    }
}

// MARK: - OptionsRow
private struct OptionsRow: View {
    let iconName: String
    let text: String
    var tint: Color = .white.opacity(0.8)
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(text)
                    .font(.manrope(.regular, size: 17))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Hem SF Symbol hem de asset desteği
                if UIImage(systemName: iconName) != nil {
                    Image(systemName: iconName)
                        .font(.system(size: 21, weight: .medium))
                        .foregroundColor(tint)
                        .frame(width: 26, height: 26)
                } else {
                    Image(iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(tint)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 22)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "#363636"))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
struct ChatRoomOptionsMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header simüle et
                Rectangle()
                    .fill(Color.red)
                    .frame(height: 70)
                ChatRoomOptionsMenuView(viewModel: ChatViewModel())
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}
