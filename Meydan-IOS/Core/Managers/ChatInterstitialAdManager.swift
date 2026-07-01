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
        do {
            try ad.canPresent(from: nil)
            ad.present(from: nil)
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
