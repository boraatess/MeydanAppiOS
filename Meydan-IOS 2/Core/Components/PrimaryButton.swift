import SwiftUI

// Projenin ana buton stili
struct PrimaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(Color.blue) //TODO: Markanın ana rengi
                .cornerRadius(12)
        }
    }
}
