import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    
    init() { // API'dan sonra burası değiştirilebilir.
        _viewModel = StateObject(wrappedValue: HomeViewModel(service: MockHomeService()))
    }
    
    var body: some View {
    
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // Üst Bar: Logo, Arama, Favoriler
                HeaderView(searchText: $viewModel.searchText)
                
                // Kategori Butonları
                CategoryButtonsView(categories: viewModel.categories)
                
                // Popüler Moderatörler Bölümü
                ContentSectionView(title: "Popüler Moderatörler") {
                    ForEach(viewModel.popularModerators) { moderator in
                        ModeratorCardView(moderator: moderator)
                    }
                }
                
                // Story'ler
                StoryListView(stories: viewModel.stories)
                
                // Popüler Odalar Bölümü
                ContentSectionView(title: "Popüler Odalar") {
                    ForEach(viewModel.popularRooms) { room in
                        RoomCardView(room: room)
                    }
                }
                
                // Takip Ettiklerinin Odaları Bölümü
                ContentSectionView(title: "Takip Ettiklerin") {
                    ForEach(viewModel.followedRooms) { room in
                        RoomCardView(room: room)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGray6)) // Arka plan
        .ignoresSafeArea(edges: .top)
    }
}


// MARK: - Alt View'lar (Daha temiz bir yapı için)

private struct HeaderView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack(spacing: 16) {
            Button {} label: {
                Image("logo") // TODO: Gerçek logo asset'i ile değiştir
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .background(Color.gray)
                    .clipShape(Circle())
            }
            
            TextField("Ara...", text: $searchText)
                .padding(12)
                .background(Color(.systemGray5))
                .cornerRadius(12)
            
            Button {} label: {
                Image("Heart")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

private struct CategoryButtonsView: View {
    let categories: [Category]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(categories) { category in
                    Button(category.name) {}
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                }
            }
            .padding(.horizontal)
        }
    }
}


private struct StoryListView: View {
    let stories: [Story]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(stories) { story in
                    VStack {
                        Image(systemName: story.imageUrl)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .padding(4)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                        
                        Text(story.username)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .frame(width: 70)
                }
            }
            .padding(.horizontal)
        }
    }
}


// MARK: - Kart View'ları

private struct ModeratorCardView: View {
    let moderator: Moderator
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: moderator.imageUrl)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(12)
            
            Text(moderator.name)
                .fontWeight(.semibold)
        }
    }
}

private struct RoomCardView: View {
    let room: Room
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: room.imageUrl)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 120)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(12)
            
            Text(room.title)
                .fontWeight(.semibold)
                .lineLimit(2)
        }
        .frame(width: 200)
    }
}


#Preview {
    HomeView()
}
