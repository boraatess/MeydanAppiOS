import SwiftUI

struct ChatRoomOptionsMenuView: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Başlık + Kapat Butonu
            HStack {
                Text("Daha fazla bilgi")
                    .font(.manrope(.bold, size: 20))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        viewModel.showMoreOptionsMenu = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.14))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // MARK: - Bilgi Metni
            Text("21.09.25 - 19.30 tarihinde @halimselim tarafından planlandı.\nSohbet spor alanı hakkında.")
                .font(.manrope(.regular, size: 16))
                .foregroundColor(.white.opacity(0.55))
                .lineSpacing(4)
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
            
            // MARK: - Eylem Butonları
            VStack(spacing: 8) {
                OptionsRow(iconName: "Add User", text: "Davet Et") {
                    viewModel.showMoreOptionsMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.showInviteSheet = true
                    }
                }
                OptionsRow(iconName: "2 User", text: "Katılımcıları Gör") {
                    viewModel.showMoreOptionsMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.showParticipantsSheet = true
                    }
                }
                OptionsRow(iconName: "Chart", text: "Anket") {
                    viewModel.showMoreOptionsMenu = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.showCreatePollSheet = true
                    }
                }
                OptionsRow(iconName: "error", text: "Yayını Şikayet Et") {
                    viewModel.reportCurrentStream()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(hex: "#2C2D2F"))
        // Sadece alt köşeleri yuvarlak göstererek header'a yapışık görünüm
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 20,
                topTrailingRadius: 0
            )
        )
        .shadow(color: Color(hex: "2C2D2F"), radius: 20, x: 0, y: 8)
    }
}

// MARK: - OptionsRow
private struct OptionsRow: View {
    let iconName: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(text)
                    .font(.manrope(.medium, size: 15))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Hem SF Symbol hem de asset desteği
                if UIImage(systemName: iconName) != nil {
                    Image(systemName: iconName)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 26, height: 26)
                } else {
                    Image(iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.07))
            )
        }
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
