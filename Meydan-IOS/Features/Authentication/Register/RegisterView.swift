import SwiftUI
import AuthenticationServices

struct RegisterView: View {
    @StateObject var viewModel: RegisterViewModel
    var onShowLogin: () -> Void
    
    @State private var showNextAfterLogin = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        
                        // --- Logo ---
                        Image("meydan_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .padding(.bottom, 16)
                            .padding(.top, 16)
                        
                        
                        // --- Kayıt Formu ---
                        VStack(spacing: 14) {
                            AuthTextField(placeholder: "Ad Soyad", text: $viewModel.fullName, errorMessage: viewModel.fullNameError)
                            AuthTextField(placeholder: "Kullanıcı Adı", text: $viewModel.username, errorMessage: $viewModel.usernameError.wrappedValue)
                            AuthTextField(placeholder: "E-Posta", text: $viewModel.email, errorMessage: viewModel.emailError)
                            
                            // Parola Alanı ve Altındaki Kural Metni
                            VStack(alignment: .leading, spacing: 8) {
                                AuthTextField(placeholder: "Parola", text: $viewModel.password, isSecure: true, errorMessage: viewModel.passwordError)
                                
                                if viewModel.passwordError == nil {
                                    Text("Şifreniz, 1 büyük karakter, 1 küçük karakter ve rakam içermelidir.")
                                        .font(.manrope(.light, size: 12))
                                        .foregroundColor(.whiteLight)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 8)
                                }
                            }
                            
                            // Parola Tekrar Alanı
                            AuthTextField(placeholder: "Parola", text: $viewModel.confirmPassword, isSecure: true, errorMessage: viewModel.confirmPasswordError)
                        }
                        .padding(.horizontal, 32)
                        
                        // --- Hata Mesajı ---
                        if let errorMessage = viewModel.generalErrorMessage {
                            Text(errorMessage)
                                .foregroundColor(.redLightError).font(.caption).multilineTextAlignment(.center)
                                .padding(.top)
                                .padding(.horizontal, 32)
                        }
                        
                        // --- Kayıt ve Giriş Butonları ---
                        VStack(spacing: 32) {
                            PrimaryButton(title: "Kayıt Ol") {
                                viewModel.register()
                            }
                            .padding(.horizontal, 32)
                            
                            // "ya da" Ayracı
                            HStack {
                                VStack { Divider().background(Color.white) }
                                Text("ya da")
                                    .foregroundColor(.whiteLight)
                                    .padding(.horizontal)
                                    .font(.manrope(.light, size: 12))
                                VStack { Divider().background(Color.white) }
                            }
                        }
                        .padding(.top, 20)
                        
                        // --- Sosyal Kayıt Butonları ---
                        SocialLoginButtonsView(
                            onGoogleTap: {
                                Task { await viewModel.signInWithGoogle() }
                            },
                            appleButton: {
                                SignInWithAppleButton(
                                    .signIn,
                                    onRequest: { request in
                                        request.requestedScopes = [.fullName, .email]
                                    },
                                    onCompletion: { result in
                                        Task { await viewModel.handleAppleSignIn(result: result) }
                                    }
                                )
                                .signInWithAppleButtonStyle(.white)
                            }
                        )
                        .padding(.top)
                        .padding(.horizontal, 32)
                        
                        Button(action: onShowLogin) {
                            HStack(spacing: 0) {
                                Text("Hesabın var mı? ")
                                    .foregroundColor(.white)
                                Text("Giriş Yap")
                                    .bold()
                                    .foregroundColor(.branding)
                            }
                            .font(.manrope(.regular, size: 12))
                        }
                        .padding(.bottom, 16)
                    }
                    .padding(.top, geometry.safeAreaInsets.top)
                    .padding(.bottom, 20)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        // Kayıt başarılı olduğunda doğrudan login ekranını göster
        .onChange(of: viewModel.isRegistered) { newValue in
            if newValue {
                onShowLogin()
            }
        }
        // Sosyal giriş başarılı olduğunda bir view göstermek istiyorsanız burada gerçek bir View döndür
        .fullScreenCover(isPresented: $showNextAfterLogin) {
            EmptyView()
        }
        // Sosyal giriş state değişimini dinle
        .onChange(of: viewModel.isLoggedIn) { newValue in
            if newValue {
                showNextAfterLogin = true
            }
        }
        .loadingOverlay(isPresented: $viewModel.isLoading, message: "Kayıt yapılıyor…")
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RegisterView(
                viewModel: RegisterViewModel(authService: AuthService(), authManager: AuthenticationManager(), authFlowState: AuthenticationFlowState(), appFlowState: AppFlowState()),
                onShowLogin: {}
            )
        }
    }
}

