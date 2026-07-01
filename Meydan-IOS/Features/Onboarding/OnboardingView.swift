import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let index: Int
    let imageName: String
    let title: String
    let description: String
}

struct OnboardingView: View {
    @EnvironmentObject private var appFlowState: AppFlowState
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            index: 0,
            imageName: "onboarding1",
            title: "Meydan'a Hoşgeldiniz!",
            description: "Maçlar, diziler, konserler... İzlediğiniz her anı başkalarıyla paylaş. Meydan'da canlı yayın sırasında anlık sohbet odalarına katılın, birlikte anı yaşayın." ),
        OnboardingPage(
            index: 1,
            imageName: "onboarding2",
            title: "\"Anı Paylaş\"",
            description: "Sohbet geçmişi tutulmaz. Her şey canlı, her şey o ana ait. Gol anı, final sahnesi, sürpriz sonlar... Anın tadını çıkar." ),
        OnboardingPage(
            index: 2,
            imageName: "onboarding3",
            title: "\"Meydan Senin\"",
            description: "Topluluğa katıl, heyecanı paylaş, birlikte yaşa. Aynı yayını izleyen insanlarla anında etkileşime geç." )
    ]
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                ForEach(pages) { page in
                    OnboardingPageView(page: page)
                        .ignoresSafeArea(.all)
                        .tag(page.index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            VStack {
                // Logo placeholder at the top
                Image("meydan_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .padding(.top, 50)
                
                Spacer()
                
                // Bottom content overlay
                VStack(spacing: 20) {
                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                                .frame(width: currentPage == index ? 24 : 8, height: 4)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Buttons based on page
                    if currentPage == 0 {
                        PrimaryButton(title: "Hadi Başlayalım") {
                            withAnimation {
                                currentPage = 1
                            }
                        }
                    } else if currentPage == 1 {
                        VStack(spacing: 12) {
                            PrimaryButton(title: "Devam Et") {
                                withAnimation {
                                    currentPage = 2
                                }
                            }
                            
                            Button("Atla") {
                                withAnimation {
                                    currentPage = 2
                                }
                            }
                            .font(.manrope(.bold, size: 16))
                            .foregroundColor(.whiteLight)
                            .padding(.vertical, 12)
                        }
                    } else {
                        VStack(spacing: 12) {
                            PrimaryButton(title: "Giriş Yap") {
                                completeOnboarding(showLogin: true)
                            }
                            
                            Button(action: {
                                completeOnboarding(showLogin: false)
                            }) {
                                Text("Kayıt Ol")
                                    .font(.manrope(.bold, size: 16))
                                    .foregroundColor(.whiteLight)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.whiteLight.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func completeOnboarding(showLogin: Bool) {
        UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
        UserDefaults.standard.set(showLogin, forKey: "authInitialShowLogin")
        appFlowState.navigate(to: .auth)
        
    }
    
}

struct OnboardingPageView: View {
    
    let page: OnboardingPage
    
    var body: some View {
        ZStack {
            // Background Image
            if let uiImage = UIImage(named: page.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .clipped()
                    .ignoresSafeArea(.all)
            } else {
                // Fallback background during dev without images
                Color.background
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .overlay(
                        Text(page.imageName)
                            .foregroundColor(.white.opacity(0.3))
                    )
                    .ignoresSafeArea(.all)
            }
            
            // Gradient Overlay for text readability
            
            LinearGradient(
                colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.8),
                    Color.black
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 16) {
                Spacer()
                
                if page.index == 0 {
                    
                    Text(page.title)
                        .font(.manrope(.bold, size: 32))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(page.description)
                        .font(.manrope(.regular, size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                        .padding(.bottom, 200)
                    
                }
                else {
                    Text(page.title)
                        .font(.manrope(.bold, size: 32))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(page.description)
                        .font(.manrope(.regular, size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                        .padding(.bottom, 250)
                }
             
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppFlowState())
        .environmentObject(AuthenticationManager())
        .preferredColorScheme(.dark)
}
