import SwiftUI

struct RoomOptionsPopUp: View {
    let onDismiss: () -> Void
    let onShare: () -> Void
    let onReport: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onShare) {
                HStack(spacing: 12) {
                    Spacer()
                    Image("share")
                        .font(.system(size: 18, weight: .medium))
                    Text("Paylaş")
                        .font(.manrope(.medium, size: 16))
                    Spacer()
                }
                .foregroundColor(.white)
                .frame(height: 46)
            }
            .buttonStyle(.plain)
            
            Divider()
                .background(Color.white.opacity(0.14))
                .padding(.horizontal, 12)
            
            Button(action: onReport) {
                HStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 20, weight: .medium))
                    Text("Şikayet Et")
                        .font(.manrope(.medium, size: 16))
                    Spacer()
                }
                .foregroundColor(.white)
                .frame(height: 46)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 306)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 8)
    }
}
