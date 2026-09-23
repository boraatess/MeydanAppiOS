import SwiftUI

enum SearchFilterType: String, CaseIterable, Identifiable {
    case people = "Kişiler"
    case chats = "Sohbetler"

    var id: String { rawValue }
}

struct SearchFilterChipsView: View {
    @Binding var selectedFilter: SearchFilterType
    var horizontalPadding: CGFloat = 20

    var body: some View {
        HStack(spacing: 12) {
            ForEach(SearchFilterType.allCases) { filter in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.manrope(.medium, size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            selectedFilter == filter
                                ? Color.branding
                                : Color.white.opacity(0.1)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, horizontalPadding)
    }
}
