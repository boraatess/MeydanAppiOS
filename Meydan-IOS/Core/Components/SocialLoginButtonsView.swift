import SwiftUI
import AuthenticationServices

struct SocialLoginButtonsView<AppleButton: View>: View {
    var onGoogleTap: () -> Void
    let appleButton: AppleButton

    init(
        onGoogleTap: @escaping () -> Void,
        @ViewBuilder appleButton: () -> AppleButton
    ) {
        self.onGoogleTap = onGoogleTap
        self.appleButton = appleButton()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            
            // Google Butonu
            Button(action: onGoogleTap) {
                HStack {
                    Image("google_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                    
                    Text("Google ile devam et")
                        .font(.manrope(.bold, size: 18))
                        .foregroundColor(.black)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.white)
                .cornerRadius(16)
            }
            
            appleButton
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .contentShape(Rectangle())
                .cornerRadius(16)
                .background(Color.clear)
                .zIndex(1)
        }
    }
}
