import SwiftUI
import UIKit
import GoogleMobileAds

struct AdMobBannerAdView: View {
    private static let adWidth: CGFloat = 320
    private static let adHeight: CGFloat = 220

    let adUnitID: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.08))

            if RuntimeEnvironment.isSwiftUIPreview {
                Text("Reklam")
                    .font(.manrope(.semiBold, size: 14))
                    .foregroundColor(.white.opacity(0.7))
            } else {
                AdMobBannerAdRepresentable(adUnitID: adUnitID)
                    .frame(width: Self.adWidth, height: Self.adHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .frame(width: Self.adWidth, height: Self.adHeight)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct AdMobBannerAdRepresentable: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: inlineAdaptiveBanner(width: 320, maxHeight: 220))
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.firstRootViewController
        DispatchQueue.main.async {
            bannerView.load(Request())
        }
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        uiView.adUnitID = adUnitID

        if uiView.rootViewController == nil {
            uiView.rootViewController = UIApplication.shared.firstRootViewController
        }
    }
}

private extension UIApplication {
    var firstRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
