
import SwiftUI

struct SplashView: View {
    var onAnimationComplete: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VideoPlayerView(videoName: "Meydan", videoType: "mp4") {
                onAnimationComplete?()
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    SplashView()
        .preferredColorScheme(.dark)
}
