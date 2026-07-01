import SwiftUI
import AVKit

struct VideoPlayerView: UIViewRepresentable {
    let videoName: String
    let videoType: String
    var onComplete: (() -> Void)?

    func makeUIView(context: Context) -> UIView {
        let view = VideoContainerView(onComplete: onComplete)
        
        guard let path = Bundle.main.path(forResource: videoName, ofType: videoType) else {
            print("DEBUG: Video file \(videoName).\(videoType) not found in bundle.")
            // If video not found, trigger completion after a short delay to not get stuck
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete?()
            }
            return view
        }
        
        let player = AVPlayer(url: URL(fileURLWithPath: path))
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        
        view.player = player
        view.layer.addSublayer(playerLayer)
        
        player.play()
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let container = uiView as? VideoContainerView {
            container.updateLayerFrame()
        }
    }
}

class VideoContainerView: UIView {
    var player: AVPlayer?
    var onComplete: (() -> Void)?
    
    init(onComplete: (() -> Void)?) {
        self.onComplete = onComplete
        super.init(frame: .zero)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        DispatchQueue.main.async {
            self.onComplete?()
        }
    }
    
    func updateLayerFrame() {
        self.layer.sublayers?.forEach { $0.frame = self.bounds }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerFrame()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
