//
//  FavoritesView.swift
//  Meydan-IOS
//

import Foundation
import SwiftUI

struct FavoriteStreamer: Identifiable {
    let id: String
    let isLive: Bool
    let title: String?
    let name: String
    let username: String
    let imageName: String
}

@MainActor
final class FavoriteStreamersViewModel: ObservableObject {
    @Published var streamers: [FavoriteStreamer] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userService: UserServiceProtocol

    init(userService: UserServiceProtocol = UserService.shared) {
        self.userService = userService
    }

    func fetchFavorites() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await userService.getMyFavorites()
            streamers = response.favorites.map(Self.mapFavorite)
        } catch {
            errorMessage = error.localizedDescription
            streamers = []
        }

        isLoading = false
    }

    private static func mapFavorite(_ favorite: FavoriteStreamerResponse) -> FavoriteStreamer {
        SearchDataHelper.mapFavorite(favorite)
    }
}

struct FavoriteStreamersView: View {
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var searchFilter: SearchFilterType = .people
    @StateObject private var viewModel = FavoriteStreamersViewModel()
    @StateObject private var searchViewModel = SearchViewModel()

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 16) {
                MainHeaderView(
                    searchText: $searchText,
                    isSearchActive: $isSearchActive,
                    showsFavoritesButton: false,
                    onFavoritesTapped: {}
                )

                if isSearchActive {
                    SearchFilterChipsView(selectedFilter: $searchFilter)
                }
            }
            .padding(.bottom, 16)

            if isSearchActive {
                SearchResultsView(
                    filter: searchFilter,
                    searchText: searchText,
                    people: searchViewModel.people,
                    rooms: searchViewModel.rooms,
                    isLoading: searchViewModel.isLoading,
                    errorMessage: searchViewModel.errorMessage
                )
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(16)
        .background(Color.background.ignoresSafeArea(edges: .bottom))
        .onChange(of: searchText) { newValue in
            guard isSearchActive else { return }
            searchViewModel.search(query: newValue)
        }
        .onChange(of: isSearchActive) { isActive in
            if isActive {
                searchViewModel.search(query: searchText)
            } else {
                searchViewModel.reset()
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.fetchFavorites()
        }
        .refreshable {
            await viewModel.fetchFavorites()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.streamers.isEmpty {
            Spacer()
            ProgressView()
                .tint(.white)
            Spacer()
        } else if let errorMessage = viewModel.errorMessage, viewModel.streamers.isEmpty {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.branding)
                Text(errorMessage)
                    .font(.manrope(.medium, size: 14))
                    .foregroundColor(.grayLight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button("Tekrar Dene") {
                    Task {
                        await viewModel.fetchFavorites()
                    }
                }
                .font(.manrope(.bold, size: 14))
                .foregroundColor(.white)
            }
            Spacer()
        } else if viewModel.streamers.isEmpty {
            Spacer()
            Text("Henüz favori yayıncın yok.")
                .font(.manrope(.medium, size: 14))
                .foregroundColor(.grayLight)
            Spacer()
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(viewModel.streamers) { streamer in
                        StreamerCardView(streamer: streamer)
                    }
                }
                .padding(.bottom)
            }
        }
    }
}

struct StreamerCardView: View {
    let streamer: FavoriteStreamer

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                if streamer.isLive {
                    Circle()
                        .stroke(Color.branding, lineWidth: 2)
                        .frame(width: 52, height: 52)
                }

                FavoriteStreamerAvatar(source: streamer.imageName)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                if streamer.isLive, let title = streamer.title {
                    Text(title)
                        .font(.manrope(.bold, size: 16))
                        .foregroundColor(.branding)
                }

                HStack(spacing: 4) {
                    Text(streamer.name)
                        .font(.manrope(.bold, size: 14))
                        .foregroundColor(.white)
                    Text(streamer.username)
                        .font(.manrope(.medium, size: 12))
                        .foregroundColor(.grayLight)
                }
            }

            Spacer()

            if streamer.isLive {
                Text("Canlı")
                    .font(.manrope(.bold, size: 10))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.branding)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.grayDark)
        .cornerRadius(16)
    }
}

private struct FavoriteStreamerAvatar: View {
    let source: String

    var body: some View {
        if let url = URL(string: source), url.scheme != nil {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    placeholder
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
        } else if UIImage(named: source) != nil {
            Image(source)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFill()
            .foregroundColor(.grayLight)
    }
}

#Preview {
    NavigationStack {
        FavoriteStreamersView()
    }
}
