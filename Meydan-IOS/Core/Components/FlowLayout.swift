import SwiftUI

struct FlowLayout<Data: Collection, Content: View>: View where Data.Element: Hashable {
    private let data: Data
    private let spacing: CGFloat
    @ViewBuilder private let content: (Data.Element) -> Content

    @State private var availableWidth: CGFloat = 0

    init(data: Data, spacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .leading, vertical: .center)) {
            Color.clear
                .frame(height: 1)
                .readSize { size in
                    availableWidth = size.width
                }

            VStack(alignment: .center, spacing: spacing) {
                ForEach(computeRows(), id: \.self) { rowElements in
                    HStack(spacing: spacing) {
                        ForEach(rowElements, id: \.self) { element in
                            content(element)
                        }
                    }
                }
            }
        }
    }
    
    private func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRowWidth: CGFloat = 0
        let aSpacing = spacing

        for element in data {
            let elementWidth = self.width(for: element)

            if currentRowWidth + elementWidth + aSpacing > availableWidth {
                rows.append([element])
                currentRowWidth = elementWidth
            } else {
                rows[rows.count - 1].append(element)
                currentRowWidth += elementWidth + aSpacing
            }
        }
        return rows
    }

    private func width(for element: Data.Element) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 16, weight: .bold)
        let attributes = [NSAttributedString.Key.font: font]
        let text = (element as? Interest)?.name ?? ""
        let size = (text as NSString).size(withAttributes: attributes)
        // Padding ve diğer boşluklar için ek pay
        return size.width + 32
    }
}


// View'ın boyutunu okumak için bir extension
extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
