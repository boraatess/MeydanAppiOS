import SwiftUI

struct CategoryScrollView: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    let onSelect: (Category) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory?.id == category.id,
                        action: { onSelect(category) }
                    )
                }
            }
            .padding(.horizontal, 28)
        }
    }
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.name)
                .font(.manrope(.medium, size: 14))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.1))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        }
    }
}

