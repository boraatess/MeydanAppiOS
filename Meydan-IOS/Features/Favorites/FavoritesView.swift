//
//  FavoritesView.swift
//  Meydan-IOS
//

import Foundation
import SwiftUI


struct FavoriteStreamersView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var selectedProfile: FavoriteStreamer?
    @State private var chatDestination: ChatDestination?
    @State private var roomAccessError: String?
    @State private var roomAccessMessage: String?
    @StateObject private var viewModel = FavoriteStreamersViewModel()
    private let horizontalInset: CGFloat = 8

    var body: some View {
        VStack(spacing: 8) {
            FavoriteStreamersHeaderView(
                title: "Favori Yayıncılar",
                searchText: $searchText,
                isSearchActive: $isSearchActive,
                onBackTapped: { dismiss() }
            )
            .padding(.bottom, 16)

            content
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, horizontalInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.background.ignoresSafeArea())
        .background(profileNavigationLink)
        .onChange(of: isSearchActive) { isActive in
            if !isActive {
                searchText = ""
            }
        }
        .fullScreenCover(item: $chatDestination) { destination in
            ChatView(
                roomId: destination.roomId,
                roomTitle: destination.roomTitle,
                roomOwnerUsername: destination.roomOwnerUsername,
                roomOwnerUserId: destination.roomOwnerUserId
            )
        }
        .alert("Sohbete Katılamıyorsunuz", isPresented: Binding(
            get: { roomAccessError != nil },
            set: { isPresented in
                if !isPresented {
                    roomAccessError = nil
                }
            }
        )) {
            Button("Tamam", role: .cancel) { roomAccessError = nil }
        } message: {
            Text(roomAccessError ?? "")
        }
        .overlay(alignment: .top) {
            if let roomAccessMessage {
                TransientToastView(message: roomAccessMessage)
                    .padding(.top, 12)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.fetchFavorites()
        }
        .refreshable {
            await viewModel.fetchFavorites(force: true)
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
                        await viewModel.fetchFavorites(force: true)
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
                    ForEach(filteredStreamers) { streamer in
                        StreamerCardView(
                            streamer: streamer,
                            onCardTap: {
                                if let destination = ChatDestination(favoriteStreamer: streamer) {
                                    openChatIfPossible(destination)
                                } else {
                                    selectedProfile = streamer
                                }
                            },
                            onAvatarTap: {
                                selectedProfile = streamer
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom)
            }
        }
    }

    private var filteredStreamers: [FavoriteStreamer] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return viewModel.streamers }

        return viewModel.streamers.filter { streamer in
            streamer.name.localizedCaseInsensitiveContains(query)
                || streamer.username.localizedCaseInsensitiveContains(query)
                || (streamer.title?.localizedCaseInsensitiveContains(query) == true)
        }
    }

    private func openChatIfPossible(_ destination: ChatDestination) {
        Task {
            do {
                let access = try await RoomAccessHelper.validateAccess(
                    roomId: destination.roomId,
                    roomOwnerUserId: destination.roomOwnerUserId
                )
                await showAccessMessageIfNeeded(access?.message)
                chatDestination = destination
            } catch {
                roomAccessError = error.localizedDescription
            }
        }
    }

    private func showAccessMessageIfNeeded(_ message: String?) async {
        guard let message = message?.trimmingCharacters(in: .whitespacesAndNewlines),
              !message.isEmpty else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            roomAccessMessage = message
        }

        try? await Task.sleep(nanoseconds: 700_000_000)

        withAnimation(.easeOut(duration: 0.2)) {
            roomAccessMessage = nil
        }
    }

    @ViewBuilder
    private var profileNavigationLink: some View {
        if let selectedProfile {
            NavigationLink(
                destination: OtherUserProfileView(
                    userId: selectedProfile.id,
                    name: selectedProfile.name,
                    username: selectedProfile.username
                ),
                isActive: Binding(
                    get: { self.selectedProfile != nil },
                    set: { isActive in
                        if !isActive {
                            self.selectedProfile = nil
                        }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        }
    }
}

private struct FavoriteStreamersHeaderView: View {
    let title: String
    @Binding var searchText: String
    @Binding var isSearchActive: Bool
    let onBackTapped: () -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Button(action: onBackTapped) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Text(title)
                    .font(.manrope(.bold, size: 18))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer()
            }

            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image("Search")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.white)

                    TextField("Ara", text: $searchText)
                        .font(.manrope(.medium, size: 14))
                        .foregroundColor(.white)
                        .tint(.white)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .lineLimit(1)

                    if isSearchActive && !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )

                if isSearchActive {
                    Button("Vazgeç") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isSearchActive = false
                            searchText = ""
                            isSearchFocused = false
                        }
                    }
                    .font(.manrope(.bold, size: 14))
                    .foregroundColor(.white)
                    .buttonStyle(.plain)
                    .fixedSize()
                }
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .onChange(of: isSearchFocused) { focused in
            guard focused else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isSearchActive = true
            }
        }
    }
}

struct StreamerCardView: View {
    let streamer: FavoriteStreamer
    var onCardTap: () -> Void = {}
    var onAvatarTap: () -> Void = {}
    
    var body: some View {
        Button(action: onCardTap) {
            HStack(spacing: 16) {
            Button(action: onAvatarTap) {
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
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                if streamer.isLive, let title = streamer.title {
                    Text(title)
                        .font(.manrope(.bold, size: 16))
                        .foregroundColor(.branding)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                HStack(spacing: 4) {
                    Text(streamer.name)
                        .font(.manrope(.bold, size: streamer.isLive ? 14 : 16))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1)

                    Text(streamer.username)
                        .font(.manrope(.medium, size: 12))
                        .foregroundColor(.grayLight)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            
            if streamer.isLive {
                Text("Canlı")
                    .font(.manrope(.bold, size: 10))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.branding)
                    .clipShape(Capsule())
                    .fixedSize()
            }
        }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.grayDark)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
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
