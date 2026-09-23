import UIKit
@preconcurrency import GoogleMobileAds

@MainActor
final class ChatInterstitialAdManager: NSObject, ObservableObject {
    private var interstitialAd: InterstitialAd?
    private var isLoading = false
    private var shouldPresentWhenLoaded = false
    private var completion: (() -> Void)?

    func preload() {
        guard !RuntimeEnvironment.isSwiftUIPreview,
              interstitialAd == nil,
              !isLoading else { return }

        loadAd()
    }

    func present(completion: @escaping () -> Void = {}) {
        guard !RuntimeEnvironment.isSwiftUIPreview else {
            completion()
            return
        }

        guard self.completion == nil else { return }
        self.completion = completion
        shouldPresentWhenLoaded = true

        if let interstitialAd {
            present(interstitialAd)
        } else if !isLoading {
            loadAd()
        }
    }

    private func loadAd() {
        isLoading = true

        InterstitialAd.load(
            with: AdMobConfig.roomInterstitialAdUnitID,
            request: Request()
        ) { [weak self] ad, _ in
            let adBox = UncheckedSendableBox(value: ad)

            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false

                guard let ad = adBox.value else {
                    if self.shouldPresentWhenLoaded {
                        self.finishPresentation()
                    }
                    return
                }

                ad.fullScreenContentDelegate = self
                self.interstitialAd = ad

                if self.shouldPresentWhenLoaded {
                    self.present(ad)
                }
            }
        }
    }

    private func present(_ ad: InterstitialAd) {
        guard let viewController = UIApplication.shared.topMostViewController else {
            finishPresentation()
            return
        }

        do {
            try ad.canPresent(from: viewController)
            ad.present(from: viewController)
        } catch {
            finishPresentation()
        }
    }

    private func finishPresentation() {
        interstitialAd = nil
        shouldPresentWhenLoaded = false
        let completion = completion
        self.completion = nil
        completion?()
    }
}

private extension UIApplication {
    var topMostViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController?
            .topMostPresentedViewController
    }
}

private extension UIViewController {
    var topMostPresentedViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.topMostPresentedViewController
        }

        if let navigationController = self as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.topMostPresentedViewController
        }

        if let tabBarController = self as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.topMostPresentedViewController
        }

        return self
    }
}

private struct UncheckedSendableBox<Value>: @unchecked Sendable {
    let value: Value
}

extension ChatInterstitialAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finishPresentation()
        preload()
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        finishPresentation()
        preload()
    }
}
