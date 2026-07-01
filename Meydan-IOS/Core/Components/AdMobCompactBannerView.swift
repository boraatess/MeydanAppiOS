import SwiftUI
import UIKit
import GoogleMobileAds

struct AdMobCompactBannerView: View {
    private static let adWidth: CGFloat = 320
    private static let adHeight: CGFloat = 50

    let adUnitID: String

    var body: some View {
        Group {
            if RuntimeEnvironment.isSwiftUIPreview {
                previewPlaceholder
            } else {
                AdMobCompactBannerRepresentable(adUnitID: adUnitID)
            }
        }
        .frame(width: Self.adWidth, height: Self.adHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .frame(maxWidth: .infinity)
    }

    private var previewPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#102A70"), Color(hex: "#2946A8")],
                startPoint: .leading,
                endPoint: .trailing
            )

            Text("Reklam")
                .font(.manrope(.semiBold, size: 12))
                .foregroundColor(.white)
        }
    }
}

private struct AdMobCompactBannerRepresentable: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.chatAdRootViewController
        DispatchQueue.main.async {
            bannerView.load(Request())
        }
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        uiView.adUnitID = adUnitID

        if uiView.rootViewController == nil {
            uiView.rootViewController = UIApplication.shared.chatAdRootViewController
        }
    }
}

private extension UIApplication {
    var chatAdRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
