import SwiftUI

struct AuthenticationView: View {
    @State private var showLoginView = true
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        ZStack {
            if showLoginView {
                LoginView(
                    viewModel: LoginViewModel(service: AuthService(), authManager: authManager),
                    onShowRegister: {
                    // "Kayıt Ol" butonuna basıldığında Register ekranına geç.
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showLoginView = false
                    }
                })
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.8)),
                    removal: .opacity.combined(with: .scale(scale: 1.2))
                ))
            } else {
                RegisterView(
                    viewModel: RegisterViewModel(service: AuthService(), authManager: authManager),
                    onShowLogin: {
                    // "Giriş Yap" butonuna basıldığında Login ekranına geri dön.
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showLoginView = true
                    }
                })
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.8)),
                    removal: .opacity.combined(with: .scale(scale: 1.2))
                ))
            }
        }
    }
}

#Preview {
    AuthenticationView()
}
