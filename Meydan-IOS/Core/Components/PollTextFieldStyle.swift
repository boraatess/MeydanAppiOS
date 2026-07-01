import SwiftUI

struct PollTextFieldStyle: TextFieldStyle {
    var isFocused: Bool

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.grayLight.opacity(0.18))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? Color.branding : Color.grayLight, lineWidth: 0.8)
            )
            .tint(.branding)
    }
}
