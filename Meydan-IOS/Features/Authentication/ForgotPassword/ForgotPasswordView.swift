import SwiftUI

struct ForgotPasswordView: View  {
    @ObservedObject var viewModel: ForgotPasswordViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                
                Image("meydan_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .padding(.top, 200)
                                
                // Açıklama
                // Parola sıfırlama kodunu almak için lütfen e-posta adresinizi yazınız.
                Text("E-Posta doğrulama kodunu almak için lütfen e- posta adresinizi yazınız.")
                    .font(.manrope(.medium, size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                // E-Posta Giriş Alanı
                AuthTextField(placeholder: "E-Posta", text: $viewModel.email)
                    .padding(.horizontal, 16)
                
                // Gönder Butonu
                PrimaryButton(
                    title: "Gönder", // Matching design "Gönder"
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        await viewModel.sendPasswordResetRequest()
                    }
                }
                .padding(.horizontal, 16)
                
                // Hata veya Başarı Mesajı
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                Spacer()
                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView(viewModel: ForgotPasswordViewModel( authFlowState: AuthenticationFlowState()))
}
