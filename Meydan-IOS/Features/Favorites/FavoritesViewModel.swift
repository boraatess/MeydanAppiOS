//
//  FavoritesViewModel.swift
//  Meydan-IOS
//
//  Created by bora ateş on 7.08.2026.
//

import Foundation

struct FavoriteStreamer: Identifiable, Hashable {
    let id: String
    let isLive: Bool
    let liveRoomId: String?
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
    private let cacheKey = "favorites.streamers"
    private let cacheTTL: TimeInterval = 120

    init(userService: UserServiceProtocol = UserService.shared) {
        self.userService = userService
    }

    func fetchFavorites(force: Bool = false) async {
        if RuntimeEnvironment.isSwiftUIPreview {
            if streamers.isEmpty {
                streamers = Self.previewStreamers
            }
            isLoading = false
            errorMessage = nil
            return
        }

        if !force,
           let cached: [FavoriteStreamer] = AppMemoryCache.shared.value(forKey: cacheKey, maxAge: cacheTTL) {
            streamers = cached
            errorMessage = nil
            return
        }

        isLoading = streamers.isEmpty
        errorMessage = nil

        do {
            let response = try await userService.getMyFavorites()
            streamers = response.favorites
                .map(Self.mapFavorite)
                .sorted { lhs, rhs in
                    if lhs.isLive != rhs.isLive {
                        return lhs.isLive && !rhs.isLive
                    }
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
            AppMemoryCache.shared.set(streamers, forKey: cacheKey)
        } catch {
            errorMessage = error.localizedDescription
            if streamers.isEmpty {
                streamers = []
            }
        }

        isLoading = false
    }

    private static func mapFavorite(_ favorite: FavoriteStreamerResponse) -> FavoriteStreamer {
        SearchDataHelper.mapFavorite(favorite)
    }

    static let previewStreamers: [FavoriteStreamer] = [
        FavoriteStreamer(
            id: "preview-live-1",
            isLive: true,
            liveRoomId: "preview-room-1",
            title: "Game of Thrones",
            name: "Ece Çiçek",
            username: "@cicekece",
            imageName: "person.crop.circle.fill"
        ),
        FavoriteStreamer(
            id: "preview-live-2",
            isLive: true,
            liveRoomId: "preview-room-2",
            title: "Türkiye - İspanya Maçı",
            name: "Arda Ulusoy",
            username: "@ardaulusoy",
            imageName: "person.crop.circle.fill"
        ),
        FavoriteStreamer(
            id: "preview-offline-1",
            isLive: false,
            liveRoomId: nil,
            title: nil,
            name: "Bora Ateş",
            username: "@boraates",
            imageName: "person.crop.circle.fill"
        )
    ]
}
