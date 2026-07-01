import SwiftUI
import UIKit

/// UIActivityViewController'ı SwiftUI içinde kullanmak için wrapper.
/// Kullanım: .sheet(isPresented: $show) { ShareActivityView(items: [url]) }
struct ShareActivityView: UIViewControllerRepresentable {
    let items: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
