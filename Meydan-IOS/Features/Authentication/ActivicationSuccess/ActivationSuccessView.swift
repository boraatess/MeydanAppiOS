import SwiftUI

struct ActivationSuccessView: View {
    enum Mode: Equatable {
        case activation(email: String)
        case resetPassword(email: String)
        
        var email: String {
            switch self {
            case .activation(let email), .resetPassword(let email): return email
            }
        }
        // Hesabın Etkinleştirildi!
        var title: String {
            switch self {
            case .activation: return "Hesabın Etkinleştirildi!"
            case .resetPassword: return "Şifreniz Onaylandı"
            }
        }
        
        var message: String {
            switch self {
            case .activation(let email):
                return "\(email) adresi için aktivasyon tamamlandı. Artık giriş yapabilirsin."
            case .resetPassword:
                return "Parolanız başarıyla sıfırlandı. Artık yeni parolanızla giriş yapabilirsiniz."
            }
        }
        
        var primaryButtonTitle: String {
            return "Giriş Ekranına Dön"
        }
    }
    
    @EnvironmentObject var authFlowState: AuthenticationFlowState
    let mode: Mode
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Başarı İkonu
                Image("Success") // Assuming this matches the design's badge icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                
                VStack(spacing: 12) {
                    Text(mode.title)
                        .font(.manrope(.extraBold, size: 25))
                        .foregroundColor(.whiteLight)
                        .multilineTextAlignment(.center)
                    
                    Text("Ana sayfaya yönlendiriliyorsunuz")
                        .font(.manrope(.medium, size: 14))
                        .foregroundColor(.grayLight)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Optional: Auto-navigate after delay if that's the intention
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                authFlowState.navigateToRoot()
            }
        }
    }
}

#Preview {
    ActivationSuccessView(mode: .activation(email: "user@example.com"))
        .environmentObject(AuthenticationFlowState())
}

#Preview {
    ActivationSuccessView(mode: .resetPassword(email: "user@example.com"))
        .environmentObject(AuthenticationFlowState())
}
