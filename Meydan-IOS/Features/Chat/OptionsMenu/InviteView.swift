import SwiftUI

struct InviteView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var searchText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Davet Et")
                    .font(.manrope(.bold, size: 20))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { 
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        viewModel.showInviteSheet = false 
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                // Kullanıcı adı ile davet et
                HStack {
                    TextField("Kullanıcı adı ile davet et", text: $searchText)
                        .font(.manrope(.medium, size: 14))
                        .foregroundColor(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.send)
                        .onSubmit {
                            sendInvite()
                        }
                        .onChange(of: searchText) { _ in
                            viewModel.inviteErrorMessage = nil
                            viewModel.inviteSuccessMessage = nil
                        }
                    
                    Spacer()
                    
                    Button(action: sendInvite) {
                        if viewModel.isInvitingUser {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(viewModel.isInvitingUser || searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(Color(hex: "#2C2C2C"))
                .cornerRadius(12)
                
                if let errorMessage = viewModel.inviteErrorMessage {
                    Text(errorMessage)
                        .font(.manrope(.medium, size: 13))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if let successMessage = viewModel.inviteSuccessMessage {
                    Text(successMessage)
                        .font(.manrope(.medium, size: 13))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Davetiye bağlantısını kopyala
                Button(action: {
                    UIPasteboard.general.string = "https://meydan.app/davet/XYZ123"
                }) {
                    HStack {
                        Text("Davetiye bağlantısını kopyala")
                            .font(.manrope(.medium, size: 14))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Color(hex: "#2C2C2C"))
                    .cornerRadius(12)
                }
                
                // Social Icons Row
                HStack(spacing: 24) {
                    SocialIcon(imageName: "whatsappLogo", color: .green)
                    SocialIcon(imageName: "facebookLogo", color: .blue)
                    SocialIcon(imageName: "instagramLogo", color: .pink)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
        .background(Color(hex: "#121212"))
        .cornerRadius(24)
        .padding(.horizontal, 16)
        .onAppear {
            viewModel.resetInviteState()
        }
        .onChange(of: viewModel.inviteSuccessMessage) { message in
            if message != nil {
                searchText = ""
            }
        }
    }
    
    private func sendInvite() {
        viewModel.inviteUser(username: searchText)
    }
}

private struct SocialIcon: View {
    let imageName: String
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color.opacity(0.1))
            .frame(width: 44, height: 44)
            .overlay(
                Image(imageName) // Placeholder for actual social logos
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(color)
            )
    }
}

struct InviteView_Previews: PreviewProvider {
    static var previews: some View {
        InviteView(viewModel: ChatViewModel())
            .preferredColorScheme(.dark)
    }
}
