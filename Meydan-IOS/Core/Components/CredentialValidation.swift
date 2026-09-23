import Foundation

enum CredentialValidation {
    static func containsEmoji(_ value: String) -> Bool {
        value.unicodeScalars.contains {
            $0.properties.isEmojiPresentation ||
            ($0.properties.isEmoji && $0.value > 0x7F) ||
            $0.value == 0xFE0F || $0.value == 0x20E3 || $0.value == 0x200D
        }
    }

    static func emailError(_ value: String) -> String? {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return !containsEmoji(value) && NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: value)
            ? nil : "Lütfen geçerli bir e-posta adresi girin."
    }

    static func passwordError(_ value: String) -> String? {
        containsEmoji(value) ? "Parola emoji içeremez." : nil
    }
}
