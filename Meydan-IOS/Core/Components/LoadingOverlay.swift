// LoadingOverlay.swift
import SwiftUI

private struct LoadingOverlayModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String?

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                // Dimmed background
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                // Centered loading content
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)

                    if let message, !message.isEmpty {
                        Text(message)
                            .font(.manrope(.medium, size: 14))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                }
                .padding(20)
                .background(Color.black.opacity(0.7))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isModal)
            }
        }
        // prevent interactions with underlying views while loading
        .allowsHitTesting(!isPresented ? true : false)
    }
}

public extension View {
    func loadingOverlay(isPresented: Binding<Bool>, message: String? = nil) -> some View {
        modifier(LoadingOverlayModifier(isPresented: isPresented, message: message))
    }
}
