import SwiftUI

// Bu View, bir başlık ve altında yatay kaydırılabilen herhangi bir içeriği gösterebilir
struct ContentSectionView<Content: View>: View {
    
    let title: String
    let content: Content
    
    // @ViewBuilder sayesinde dışarıdan birden fazla View'ı tek bir içerikmiş gibi alabiliriz
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Başlık ve "Tümünü Gör" butonu
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Tümünü Gör") {}
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Yatay kaydırılabilir içerik alanı
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    content
                }
                .padding(.horizontal)
            }
        }
    }
}
