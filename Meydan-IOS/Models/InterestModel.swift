import SwiftUI

// MARK: - Model
struct Interest: Identifiable, Hashable {
    let id: String
    let name: String
    let color: Color
}

extension Interest {
    static let colorPalette: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown, .gray
    ]
}

struct HobbiesResponse: Decodable {
    let message: String
    let hobbies: [Hobby]
}

struct Hobby: Decodable {
    let _id: String
    let name: String
}
