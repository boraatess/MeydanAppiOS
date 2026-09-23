import SwiftUI
import UIKit
import GoogleMobileAds

struct AdMobNativeAdCardView: View {
    let adUnitID: String

    var body: some View {
        AdMobNativeAdRepresentable(adUnitID: adUnitID)
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.10, green: 0.10, blue: 0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
    }
}

private struct AdMobNativeAdRepresentable: UIViewRepresentable {
    let adUnitID: String

    func makeCoordinator() -> Coordinator {
        Coordinator(adUnitID: adUnitID)
    }

    func makeUIView(context: Context) -> NativeAdContainerView {
        let view = NativeAdContainerView()
        context.coordinator.containerView = view
        view.showPlaceholder()

        DispatchQueue.main.async {
            context.coordinator.loadAd()
        }

        return view
    }

    func updateUIView(_ uiView: NativeAdContainerView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, @preconcurrency AdLoaderDelegate, @preconcurrency NativeAdLoaderDelegate {
        let adUnitID: String
        weak var containerView: NativeAdContainerView?
        private var adLoader: AdLoader?

        init(adUnitID: String) {
            self.adUnitID = adUnitID
        }

        func loadAd() {
            guard let rootViewController = UIApplication.shared.firstRootViewController else {
                return
            }

            let loader = AdLoader(
                adUnitID: adUnitID,
                rootViewController: rootViewController,
                adTypes: [.native],
                options: nil
            )
            loader.delegate = self
            adLoader = loader
            loader.load(Request())
        }

        func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
            containerView?.show(nativeAd: nativeAd)
        }

        func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
            containerView?.showPlaceholder()
        }
    }
}

private final class NativeAdContainerView: UIView {
    private let nativeAdView = NativeAdView()
    private let mediaView = MediaView()
    private let adBadgeLabel = UILabel()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let callToActionButton = UIButton(type: .system)
    private let iconImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func show(nativeAd: NativeAd) {
        headlineLabel.text = nativeAd.headline
        bodyLabel.text = nativeAd.body ?? nativeAd.advertiser ?? "Sponsorlu içerik"
        callToActionButton.setTitle((nativeAd.callToAction ?? "YÜKLE").uppercased(), for: .normal)

        if let icon = nativeAd.icon?.image {
            iconImageView.image = icon
            iconImageView.isHidden = false
        } else {
            iconImageView.image = nil
            iconImageView.isHidden = true
        }

        mediaView.mediaContent = nativeAd.mediaContent
        nativeAdView.nativeAd = nativeAd
    }

    func showPlaceholder() {
        headlineLabel.text = "Google Ads"
        bodyLabel.text = "Sponsorlu içerik"
        callToActionButton.setTitle("YÜKLE", for: .normal)
        iconImageView.image = UIImage(systemName: "a.circle.fill")
        iconImageView.isHidden = false
    }

    private func setupView() {
        backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1)
        clipsToBounds = true
        layer.cornerRadius = 16

        nativeAdView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nativeAdView)

        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.backgroundColor = .clear
        nativeAdView.addSubview(mediaView)

        let topStack = UIStackView(arrangedSubviews: [adBadgeLabel, UIView()])
        topStack.axis = .horizontal
        topStack.spacing = 6
        topStack.alignment = .center
        topStack.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(topStack)

        adBadgeLabel.text = "Reklam"
        adBadgeLabel.font = .systemFont(ofSize: 15, weight: .bold)
        adBadgeLabel.textColor = .white
        adBadgeLabel.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        adBadgeLabel.layer.cornerRadius = 4
        adBadgeLabel.clipsToBounds = true
        adBadgeLabel.textAlignment = .center
        adBadgeLabel.translatesAutoresizingMaskIntoConstraints = false

        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.layer.cornerRadius = 18
        iconImageView.clipsToBounds = true
        nativeAdView.addSubview(iconImageView)

        bodyLabel.font = .systemFont(ofSize: 11, weight: .medium)
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        bodyLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.isHidden = true

        headlineLabel.font = .systemFont(ofSize: 12, weight: .medium)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 1
        headlineLabel.textAlignment = .center
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.isHidden = true
        nativeAdView.addSubview(headlineLabel)

        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        callToActionButton.setTitleColor(.white, for: .normal)
        callToActionButton.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        callToActionButton.layer.cornerRadius = 8
        callToActionButton.isUserInteractionEnabled = false
        nativeAdView.addSubview(callToActionButton)

        nativeAdView.mediaView = mediaView
        nativeAdView.headlineView = headlineLabel
        nativeAdView.bodyView = bodyLabel
        nativeAdView.callToActionView = callToActionButton
        nativeAdView.iconView = iconImageView

        NSLayoutConstraint.activate([
            nativeAdView.leadingAnchor.constraint(equalTo: leadingAnchor),
            nativeAdView.trailingAnchor.constraint(equalTo: trailingAnchor),
            nativeAdView.topAnchor.constraint(equalTo: topAnchor),
            nativeAdView.bottomAnchor.constraint(equalTo: bottomAnchor),

            mediaView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            mediaView.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 18),
            mediaView.bottomAnchor.constraint(equalTo: callToActionButton.topAnchor, constant: -10),

            topStack.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
            topStack.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
            topStack.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 12),

            adBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 72),
            adBadgeLabel.heightAnchor.constraint(equalToConstant: 30),

            iconImageView.centerXAnchor.constraint(equalTo: mediaView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: mediaView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 112),
            iconImageView.heightAnchor.constraint(equalToConstant: 112),

            headlineLabel.centerXAnchor.constraint(equalTo: nativeAdView.centerXAnchor),
            headlineLabel.centerYAnchor.constraint(equalTo: nativeAdView.centerYAnchor, constant: -6),
            headlineLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nativeAdView.leadingAnchor, constant: 32),
            headlineLabel.trailingAnchor.constraint(lessThanOrEqualTo: nativeAdView.trailingAnchor, constant: -32),

            callToActionButton.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 16),
            callToActionButton.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -16),
            callToActionButton.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -14),
            callToActionButton.heightAnchor.constraint(equalToConstant: 52)
        ])
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
