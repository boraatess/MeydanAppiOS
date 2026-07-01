import SwiftUI

@MainActor
struct MainTabView: View {
    
    // Varsayılan olarak private init kullanmak,
    // bu View'ın dışarıdan yanlış başlatılmasını engeller.
    init() {
        // iOS 15 ve sonrası için TabBar'ın saydamlığını ayarlayan standart kod.
        UITabBar.appearance().isHidden = true
    }
    
    @State private var selectedTab: Tab = .home
    @State private var xAxis: CGFloat = 0 // Kavisin ve baloncuğun X konumu
    @Namespace private var animation // View'lar arası pürüzsüz geçiş için
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. İçerik Ekranları
            switch selectedTab {
            case .home:
                HomeView()
            case .category:
                Text("Kategori Sayfası").frame(maxWidth: .infinity, maxHeight: .infinity)
            case .plus:
                Text("Ekleme Sayfası").frame(maxWidth: .infinity, maxHeight: .infinity)
            case .notification:
                Text("Bildirimler Sayfası").frame(maxWidth: .infinity, maxHeight: .infinity)
            case .profile:
                Text("Profil Sayfası").frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // 2. Özel TabBar'ımız
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    GeometryReader { reader in
                        Button(action: {
                            withAnimation(.snappy) {
                                selectedTab = tab
                                // Butonun orta noktasını xAxis'e ata
                                xAxis = reader.frame(in: .global).midX
                            }
                        }) {
                            // İkon
                            Image(tab.rawValue)
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(selectedTab == tab ? Color.accentColor : .secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        // Başlangıçta Home seçili olduğu için onun pozisyonunu al
                        .onAppear {
                            if tab == .home {
                                xAxis = reader.frame(in: .global).midX
                            }
                        }
                    }
                    .frame(width: 40, height: 40) // Her buton için standart bir boyut
                }
            }
            .frame(height: 55)
            .padding(.bottom, 8) // Alttan 8 birim boşluk
            .padding([.horizontal, .top])
            .background(
                Color.white.clipShape(TabBarShape(xAxis: xAxis))
            )
            // Baloncuk ve seçili ikonun üzerine gelmesi için
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(selectedTab.rawValue)
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    )
                    // Baloncuğu animasyonlu bir şekilde hareket ettir
                    .position(x: xAxis, y: 10)
                    .animation(.snappy, value: xAxis)
            }
            .cornerRadius(25) // Dış çerçevenin köşelerini yuvarlak yap
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 0)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

#Preview {
    MainTabView()
}
