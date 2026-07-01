import SwiftUI

@MainActor
final class AppFlowState: ObservableObject {
    enum Route: Equatable {
        case onboarding
        case auth
        case birthday
        case interests
        case main
        case verifyEmail(email: String, userId: String)
    }
    
    @Published var route: Route = .auth
    @Published var deepLinkTarget: DeepLinkTarget?
    
    enum DeepLinkTarget: Equatable {
        case otherProfile(username: String)
    }
    
    func navigate(to route: Route) {
        self.route = route
    }
    
    func handleDeepLink(_ url: URL) {
        // Example URL: https://meydan.app/profile/boraates
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        if pathComponents.count >= 2, pathComponents[0] == "profile" {
            let username = pathComponents[1]
            self.deepLinkTarget = .otherProfile(username: username)
            self.navigate(to: .main)
        }
    }
}
