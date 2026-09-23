import Foundation

// Run with swiftc Core/Validation/{BlockedTerms,ContentFilter}.swift and this file.
@main
struct ContentFilterTests {
    static func main() {
        let turkish = Locale(identifier: "tr_TR")
        for term in BlockedTerms.values {
            precondition(ContentFilter.warning(for: term) != nil, "Missed document entry: \(term)")
            precondition(ContentFilter.warning(for: term.uppercased(with: turkish)) != nil,
                         "Missed uppercase entry: \(term)")
            precondition(ContentFilter.warning(for: "(\(term))") != nil,
                         "Missed punctuation boundary: \(term)")
        }

        let blocked = [
            "Bu salak!", "a.mk", "g*t", "18+", ":poop:", "31", "30+1",
            "al\n\t ağzına", "a\u{200B}mk", "ａｍｋ", "ŞEREFSİZ",
            "takip", "destek", "durum", "müslüman", "akp", "user_amk"
        ]
        for text in blocked {
            precondition(ContentFilter.warning(for: text) != nil, "Expected rejection: \(text)")
        }

        let allowed = [
            "", "  \n", "Merhaba herkese!", "normal", "tamam", "kitap", "toplantı",
            "destekli", "131", "310", "şık", "ışık", "aXmk", "gXt", "Merhaba 👋"
        ]
        for text in allowed {
            precondition(ContentFilter.warning(for: text) == nil, "Unexpected rejection: \(text)")
        }
        print("Passed: all \(BlockedTerms.values.count) document entries, Turkish case, Unicode, phrases and word boundaries.")
    }
}
