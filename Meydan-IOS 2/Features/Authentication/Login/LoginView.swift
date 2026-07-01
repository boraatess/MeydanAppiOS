import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject var viewModel: LoginViewModel
    
    var onShowRegister: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            // --- Başlık ---
            Text("Meydan'a Hoş Geldin")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Giriş yaparak etkinlikleri keşfet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // --- Giriş Alanları ---
            VStack {
                TextField("Email veya Telefon Numarası", text: $viewModel.credential)
                    .keyboardType(.default)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                
                SecureField("Şifre", text: $viewModel.password)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // --- Hata Mesajı ---
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // --- Giriş Butonu ---
            if viewModel.isLoading {
                ProgressView()
                    .padding(.vertical, 16)
            } else {
                PrimaryButton(title: "Giriş Yap") {
                    Task {
                        await viewModel.login()
                    }
                }
                .padding(.horizontal)
            }
            
            // --- AYRAÇ ---
            HStack {
                VStack { Divider() }
                Text("veya")
                    .foregroundColor(.secondary)
                VStack { Divider() }
            }
            .padding(.horizontal)
            
            // --- SOSYAL GİRİŞ BUTONLARI ---
            
            VStack(spacing: 12) {
                
                // Apple ile Giriş Butonu
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        Task {
                            await viewModel.handleAppleSignIn(result: result)
                        }
                    }
                )
                .signInWithAppleButtonStyle(.white)
                .frame(height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                
                // Google ile Giriş Butonu
                Button(action: {
                    Task {
                        await viewModel.handleSocialSignIn()
                    }
                }) {
                    HStack {
                        Image("google_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        
                        Text("Google ile Giriş Yap")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.primary)
                }
                .frame(height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                
            }
            .padding(.horizontal)
            
            Spacer()
            
            // --- Kayıt Ekranına Yönlendirme ---
            Button(action: onShowRegister) {
                HStack(spacing: 4) {
                    Text("Hesabın yok mu?")
                    Text("Kayıt Ol")
                        .fontWeight(.bold)
                }
                .font(.footnote)
            }
            .padding(.bottom)
        }
        .padding(.top)
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: LoginViewModel(service: AuthService(), authManager: AuthenticationManager()), onShowRegister: {})
    }
}
