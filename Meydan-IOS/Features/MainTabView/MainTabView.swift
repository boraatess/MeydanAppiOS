import SwiftUI

@MainActor
struct MainTabView: View {
    
    @State private var selectedTab: Tab = .home
    @State private var previousTab: Tab = .home
    @State private var profilePath: [ProfileNavigation] = []
    @State private var homePath = NavigationPath()
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    @EnvironmentObject var appFlowState: AppFlowState
    
    private var showsTabBar: Bool {
        profilePath.isEmpty && selectedTab != .plus
    }

    private let tabBarReservedHeight: CGFloat = 100
    

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(navigationPath: $homePath)
                case .discover:
                    DiscoverView()
                case .plus:
                    CreateRoomView {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = previousTab
                        }
                    }
                case .notification:
                    NotificationView()
                case .profile:
                    ProfileView(path: $profilePath)
                default:
                    Color.black.ignoresSafeArea()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if showsTabBar {
                    Color.clear.frame(height: tabBarReservedHeight)
                }
            }

            if showsTabBar {
                CustomTabBar(selectedTab: $selectedTab, previousTab: $previousTab, homePath: $homePath)
                    .padding(.horizontal, 20)
                    .padding(.bottom, -4)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(.dark)
        .onChange(of: appFlowState.deepLinkTarget) { target in
            if let target = target {
                switch target {
                case .otherProfile(let username):
                    selectedTab = .profile
                    profilePath = []
                    // Assuming you have an endpoint or logic that fetches ID from username, 
                    // or OtherUserProfileView can take just username. 
                    // Let's push to otherProfile navigation.
                    // For now, we will pass empty ID and Name, as OtherUserProfileView might need updates 
                    // to fetch user by username. We'll pass username for all fields or modify the enum.
                    profilePath.append(.otherProfile(userId: "", name: username, username: username))
                }
                // Reset target
                appFlowState.deepLinkTarget = nil
            }
        }
    }
}

private struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Binding var previousTab: Tab
    @Binding var homePath: NavigationPath
    @State private var xAxis: CGFloat = 0
    @State private var tabPositions: [Tab: CGFloat] = [:]

    private var bottomSafeArea: CGFloat {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return windowScene?.windows.first?.safeAreaInsets.bottom ?? 0
    }

    private var validTabs: [Tab] {
        Tab.allCases.filter { $0 != .testChatRoom }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Katman 1: Arka Plan
            Color.black
                .clipShape(TabBarShape(xAxis: xAxis))
            
            // Katman 2: İkonlar
            HStack(spacing: 58) {
                ForEach(validTabs, id: \.self) { tab in
                    Button {
                        if selectedTab == tab {
                            if tab == .home {
                                homePath = NavigationPath()
                            }
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if tab != .plus {
                                previousTab = tab
                            }
                            selectedTab = tab
                        }
                    } label: {
                        Image(tabIconName(tab))
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(selectedTab == tab ? .clear : .white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .contentShape(Rectangle())
                            .overlay(
                                // Butonun orta noktasını yakalamak için
                                GeometryReader { proxy in
                                    let midX = proxy.frame(in: .named("TabBar")).midX
                                    Color.clear
                                        .allowsHitTesting(false)
                                        .onAppear {
                                            tabPositions[tab] = midX
                                            if selectedTab == tab {
                                                xAxis = midX
                                            }
                                        }
                                        .onChange(of: selectedTab) { newValue in
                                            if tab == newValue {
                                                xAxis = midX
                                            }
                                        }
                                    
                                }
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 24) // Tabları merkeze doğru biraz daha yaklaştırır
            
            // Katman 3: Animasyonlu Baloncuk ve Seçili İkon
            Circle()
                .fill(Color.white)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(tabIconName(selectedTab))
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.black)
                )
                .position(x: xAxis, y: 35)
                .offset(y: -35)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                .allowsHitTesting(false) // Seçili alanın (baloncuğun) tıklamaları yutmasını engeller
            
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60 + bottomSafeArea)
        .coordinateSpace(name: "TabBar")
        .padding(.bottom, -bottomSafeArea)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func tabIconName(_ tab: Tab) -> String {
        switch tab {
        case .home: return "Home"
        case .discover: return "mdi_movie-search-outline"
        case .plus: return "Plus"
        case .notification: return "Notification"
        case .profile: return "Profile"
        case .testChatRoom: return "Chat"
        }
    }
}

/*
 
 .frame(maxWidth: .infinity) // Siyah arkaplanın ekranın sol ve sağ kenarlarına %100 yapışmasını sağlar
 .frame(height: 55 + bottomSafeArea) // Extend for safe area
 .coordinateSpace(name: "TabBar")
 .padding(.bottom, -bottomSafeArea) // Counter the height increase
 
 
 */


#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
        .environmentObject(AppFlowState())
}
