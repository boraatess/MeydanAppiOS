import SwiftUI

// Projenin ana buton stili
struct PrimaryButton: View {
    var title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            ZStack {
                // Title text remains in layout; hidden when loading to preserve size
                Text(title)
                    .font(.manrope(.bold, size: 18))
                    .foregroundColor(.whiteLight)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(.whiteLight)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.branding)
            .cornerRadius(16)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
    }
}
