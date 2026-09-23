import Foundation

enum ContentFilter {
    static let warningMessage = "Metniniz izin verilmeyen bir kelime veya ifade içeriyor. Lütfen düzenleyip tekrar deneyin."

    static func warning(for text: String) -> String? {
        let normalized = normalize(text)
        let range = NSRange(normalized.startIndex..., in: normalized)
        return expression.firstMatch(in: normalized, range: range) == nil ? nil : warningMessage
    }

    // Preserve Turkish letters: diacritic folding would also block innocent words like “şık”.
    private static func normalize(_ text: String) -> String {
        let normalized = text.precomposedStringWithCompatibilityMapping
            .lowercased(with: Locale(identifier: "tr_TR"))
        return String(normalized.unicodeScalars.filter {
            ![0x200B, 0x200C, 0x200D, 0x2060, 0xFEFF, 0x00AD].contains($0.value)
        })
    }

    private static let expression: NSRegularExpression = {
        let alternatives = Set(BlockedTerms.values.map(normalize)).sorted().map { term in
            term.split(whereSeparator: { $0.isWhitespace })
                .map { NSRegularExpression.escapedPattern(for: String($0)) }
                .joined(separator: "\\s+")
        }
        // Unicode word boundaries prevent short entries from matching inside other words/numbers.
        // Punctuation in the document is literal (e.g. “g*t” and “18+”), never regex syntax.
        let pattern = "(?<![\\p{L}\\p{M}\\p{N}])(?:" + alternatives.joined(separator: "|") + ")(?![\\p{L}\\p{M}\\p{N}])"
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            preconditionFailure("Invalid content filter expression: \(error)")
        }
    }()
}
