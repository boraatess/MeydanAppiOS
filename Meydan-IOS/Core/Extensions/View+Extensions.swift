import SwiftUI
import UIKit
import AuthenticationServices

private final class FilteringTapGestureRecognizer: UITapGestureRecognizer, UIGestureRecognizerDelegate {
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delegate = self
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view: UIView? = touch.view
        while let current = view {
            // Ignore taps on interactive controls (UIButton, UITextField, etc.)
            if current is UIControl { return false }
            // Ignore taps on text views (editable areas)
            if current is UITextView { return false }
            
            // SwiftUI internal text field views (handling various versions)
            let className = String(describing: type(of: current))
            if className.contains("TextField") || className.contains("TextView") || className.contains("Selection") {
                return false
            }
            
            // Ignore taps on Sign in with Apple button
            if let appleBtnClass = NSClassFromString("ASAuthorizationAppleIDButton"), current.isKind(of: appleBtnClass) {
                return false
            }
            view = current.superview
        }
        return true
    }
}

private final class KeyboardDismissManager {
    @MainActor static let shared = KeyboardDismissManager()
    private weak var window: UIWindow?
    private var recognizer: FilteringTapGestureRecognizer?
    private var installCount: Int = 0

    @MainActor func install() {
        installCount += 1
        guard recognizer == nil else { return }
        guard let keyWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        let gr = FilteringTapGestureRecognizer(target: self, action: #selector(handleTap))
        keyWindow.addGestureRecognizer(gr)
        self.window = keyWindow
        self.recognizer = gr
    }

    @MainActor func uninstall() {
        installCount = max(installCount - 1, 0)
        guard installCount == 0, let gr = recognizer, let win = window else { return }
        win.removeGestureRecognizer(gr)
        self.recognizer = nil
        self.window = nil
    }

    @MainActor @objc private func handleTap() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct DismissKeyboardOnTapModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                Task { @MainActor in
                    KeyboardDismissManager.shared.install()
                }
            }
            .onDisappear {
                Task { @MainActor in
                    KeyboardDismissManager.shared.uninstall()
                }
            }
    }
}

@MainActor private func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

struct ShimmerModifier: ViewModifier {
    var active: Bool
    @State private var phase: CGFloat = -1.0
    
    func body(content: Content) -> some View {
        if active {
            content
                .overlay(
                    GeometryReader { geo in
                        let width = geo.size.width
                        let height = geo.size.height
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.6), Color.clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: max(60, width * 0.6), height: height * 2)
                        .rotationEffect(.degrees(20))
                        .offset(x: phase * (width + max(60, width * 0.6)))
                        .blendMode(.screen)
                    }
                )
                .mask(content)
                .onAppear {
                    phase = -1.0
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        phase = 1.0
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.modifier(DismissKeyboardOnTapModifier())
    }
    
    func shimmer(active: Bool) -> some View {
        modifier(ShimmerModifier(active: active))
    }
    
    /// Adds pull-to-refresh behavior using SwiftUI's `.refreshable` on supported platforms.
    /// Falls back to a no-op on earlier OS versions.
    @ViewBuilder
    func pullToRefresh(_ action: @escaping @Sendable () async -> Void) -> some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            self.refreshable { await action() }
        } else {
            self
        }
    }
    
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
