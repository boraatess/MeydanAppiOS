import Foundation

enum AdMobConfig {
    static let usesTestAdUnitIDs = true

    static let appID = "ca-app-pub-9527136238888249~6841302170"

    static var homeNativeAdUnitID: String {
        usesTestAdUnitIDs ? Test.homeNativeAdUnitID : Production.homeNativeAdUnitID
    }

    static var profileNativeAdUnitID: String {
        usesTestAdUnitIDs ? Test.profileNativeAdUnitID : Production.profileNativeAdUnitID
    }

    static var homeBannerAdUnitID: String {
        usesTestAdUnitIDs ? Test.bannerAdUnitID : Production.chatBannerAdUnitID
    }

    static var chatBannerAdUnitID: String {
        usesTestAdUnitIDs ? Test.bannerAdUnitID : Production.chatBannerAdUnitID
    }

    static var roomInterstitialAdUnitID: String {
        usesTestAdUnitIDs ? Test.roomInterstitialAdUnitID : Production.roomInterstitialAdUnitID
    }
}

private extension AdMobConfig {
    enum Production {
        static let homeNativeAdUnitID = "ca-app-pub-9527136238888249/3604460827"
        static let profileNativeAdUnitID = "ca-app-pub-9527136238888249/4307168401"
        static let chatBannerAdUnitID = "ca-app-pub-9527136238888249/7658570149"
        static let roomInterstitialAdUnitID = "ca-app-pub-9527136238888249/9978297482"
    }

    enum Test {
        static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
        static let homeNativeAdUnitID = "ca-app-pub-3940256099942544/3986624511"
        static let profileNativeAdUnitID = "ca-app-pub-3940256099942544/3986624511"
        static let roomInterstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    }
}
