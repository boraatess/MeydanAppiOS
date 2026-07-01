import SwiftUI

struct MainHeaderView: View {
    @Binding var searchText: String
    @Binding var isSearchActive: Bool
    var showsFavoritesButton: Bool = true
    var onFavoritesTapped: () -> Void

    @Namespace private var animation
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if !isSearchActive {
                    Image("meydan_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .matchedGeometryEffect(id: "logo", in: animation)
                } else {
                    Color.clear
                        .frame(width: 0, height: 48)
                }
            }
            .frame(width: isSearchActive ? 0 : 48, height: 48)

            HStack(spacing: 12) {
                Image("Search")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)

                TextField("Ara", text: $searchText)
                    .font(.manrope(.medium, size: 16))
                    .foregroundColor(.white)
                    .tint(.white)
                    .focused($isSearchFocused)
                    .submitLabel(.search)

                if isSearchActive && !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .matchedGeometryEffect(id: "searchbar", in: animation)

            if isSearchActive {
                Button("Vazgeç") {
                    withAnimation(.spring()) {
                        isSearchActive = false
                        searchText = ""
                        isSearchFocused = false
                    }
                }
                .font(.manrope(.bold, size: 14))
                .foregroundColor(.white)
                .matchedGeometryEffect(id: "button", in: animation)
            } else if showsFavoritesButton {
                Button(action: onFavoritesTapped) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 48, height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                            )

                        Image("Star")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                    }
                }
                .matchedGeometryEffect(id: "button", in: animation)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .onChange(of: isSearchFocused) { focused in
            guard focused else { return }
            withAnimation(.spring()) {
                isSearchActive = true
            }
        }
    }
}

struct MainHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        MainHeaderView(
            searchText: .constant(""),
            isSearchActive: .constant(false),
            onFavoritesTapped: {}
        )
        .preferredColorScheme(.dark)
    }
}
