import SwiftUI

struct RegisterView: View {
    
    @StateObject var viewModel: RegisterViewModel
    
    var onShowLogin: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            // --- Başlık ---
            Text("Meydan'a Katıl")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Yeni bir hesap oluşturarak aramıza katıl.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // --- Giriş Alanları ---
            VStack {
                TextField("Kullanıcı Adı", text: $viewModel.username)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                
                TextField("Email Adresi", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                
                SecureField("Şifre", text: $viewModel.password)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .textContentType(.oneTimeCode)
                
                SecureField("Şifre (Tekrar)", text: $viewModel.confirmPassword)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .textContentType(.oneTimeCode) 
            }
            .padding(.horizontal)
            
            // --- Hata Mesajı ---
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            // --- Kayıt Ol Butonu ---
            if viewModel.isLoading {
                ProgressView()
                    .frame(height: 52)
            } else {
                PrimaryButton(title: "Hesap Oluştur") {
                    Task {
                        await viewModel.register()
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: onShowLogin) {
                HStack {
                    Text("Zaten bir hesabın var mı?")
                    Text("Giriş Yap")
                        .fontWeight(.bold)
                }
                .font(.footnote)
            }
            .padding(.bottom)
        }
        .padding(.top)
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RegisterView(viewModel: RegisterViewModel(service: AuthService(), authManager: AuthenticationManager()), onShowLogin: {})
        }
    }
}
