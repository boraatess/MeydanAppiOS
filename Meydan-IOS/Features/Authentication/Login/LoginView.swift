import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject var viewModel: LoginViewModel
    @EnvironmentObject var authFlowState: AuthenticationFlowState
    var onShowRegister: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    
                    // --- Logo ---
                    Image("meydan_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .padding(.bottom, 16) // Increased distance
                                        
                    // --- Giriş Formu ---
                    VStack(spacing: 16) {
                        VStack(spacing: 14) {
                            AuthTextField(placeholder: "E-Posta", text: $viewModel.credential, errorMessage: viewModel.credentialError)
                            AuthTextField(placeholder: "Parola", text: $viewModel.password, isSecure: true, errorMessage: viewModel.passwordError)
                        }
                        
                        // --- Şifremi Unuttum ---
                        Button("Şifremi unuttum") {
                            authFlowState.navigate(to: .forgotPassword)
                        }
                        .font(.manrope(.light, size: 12))
                        .foregroundColor(Color.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        if let errorMessage = viewModel.generalErrorMessage {
                            Text(errorMessage)
                                .foregroundColor(.redLightError)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // --- Giriş ve Kayıt Butonları ---
                    VStack(spacing: 16) {
                        PrimaryButton(title: "Giriş Yap") {
                            Task { await viewModel.login() }
                        }
                        .padding(.horizontal, 32)
                        
                        // --- Ya Da ---
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
                    
                    // --- Sosyal Giriş Butonları ---
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
                    .padding(.bottom, 16)
                    
                    Button(action: onShowRegister) {
                        HStack(spacing: 0) {
                            Text("Hesabın yok mu? ")
                                .foregroundColor(.white)
                            Text("Kayıt Ol")
                                .bold()
                                .foregroundColor(.branding)
                        }
                        .font(.manrope(.regular, size: 12))
                    }
                }
                .frame(height: geometry.size.height)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .loadingOverlay(isPresented: $viewModel.isLoading, message: "Giriş yapılıyor…")
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(
            viewModel: LoginViewModel(authService: AuthService(), authManager: AuthenticationManager(), authFlowState: AuthenticationFlowState()),
            onShowRegister: {}
        )
    }
}

