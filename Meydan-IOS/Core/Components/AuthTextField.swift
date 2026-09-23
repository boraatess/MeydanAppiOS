import SwiftUI

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var errorMessage: String?
    @State private var isPasswordVisible: Bool = false
    
    private var displayedError: String? {
        if let errorMessage { return errorMessage }
        if isSecure { return CredentialValidation.passwordError(text) }
        if placeholder.localizedCaseInsensitiveContains("posta"), CredentialValidation.containsEmoji(text) {
            return "E-posta adresi emoji içeremez."
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Group {
                    if isSecure && !isPasswordVisible {
                        SecureField(placeholder, text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                            .submitLabel(.done)
                    } else {
                        TextField(placeholder, text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                            .submitLabel(.done)
                    }
                }
                .foregroundStyle(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(placeholder.contains("E-Posta") ? .emailAddress : .default)
                
                if displayedError != nil {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                }
                
                if isSecure {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .font(.manrope(.medium, size: 16))
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(displayedError != nil ? Color.red : Color.white.opacity(0.2), lineWidth: 1)
            )
            .preferredColorScheme(.dark)
            
            if let errorMessage = displayedError, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.manrope(.light, size: 12))
                    .foregroundColor(.redLightError)
                    .padding(.leading, 8)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
