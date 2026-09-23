import SwiftUI

struct InviteView: View {
    @ObservedObject var viewModel: ChatViewModel
    @StateObject private var suggestionViewModel = SearchViewModel()
    @State private var searchText: String = ""
    @State private var selectedSuggestionUsername: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Davet Et")
                    .font(.manrope(.bold, size: 20))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { 
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        viewModel.showInviteSheet = false 
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    inviteInputRow

                    inviteSuggestionsView

                    shareRow
                    
                    if let errorMessage = viewModel.inviteErrorMessage {
                        Text(errorMessage)
                            .font(.manrope(.medium, size: 13))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if let successMessage = viewModel.inviteSuccessMessage {
                        Text(successMessage)
                            .font(.manrope(.medium, size: 13))
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: 380)
        .frame(maxHeight: 220)
        .background(Color(hex: "#121212"))
        .cornerRadius(24)
        .padding(.horizontal, 16)
        .onAppear {
            viewModel.resetInviteState()
        }
        .onChange(of: viewModel.inviteSuccessMessage) { message in
            if message != nil {
                searchText = ""
                suggestionViewModel.reset()
            }
        }
    }
    
    private func sendInvite() {
        viewModel.inviteUser(username: searchText)
    }

    private func normalizedUsername(_ username: String) -> String {
        username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
            .lowercased()
    }

    private var inviteInputRow: some View {
        HStack(spacing: 12) {
            TextField("Kullanıcı adı ile davet et", text: $searchText)
                .font(.manrope(.medium, size: 16))
                .foregroundColor(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.send)
                .onSubmit {
                    sendInvite()
                }
                .onChange(of: searchText) { _ in
                    viewModel.inviteErrorMessage = nil
                    viewModel.inviteSuccessMessage = nil
                    if normalizedUsername(searchText) != normalizedUsername(selectedSuggestionUsername ?? "") {
                        selectedSuggestionUsername = nil
                    }
                    suggestionViewModel.search(query: normalizedUsername(searchText))
                }

            Button(action: sendInvite) {
                if viewModel.isInvitingUser {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "paperplane")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .disabled(viewModel.isInvitingUser || searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
        .background(Color(hex: "#353535"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var shareRow: some View {
        Button {
            viewModel.shareRoom()
        } label: {
            HStack(spacing: 12) {
                Text("Paylaş")
                    .font(.manrope(.medium, size: 16))
                    .foregroundColor(.white)

                Spacer()
                
                Image("share")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(Color(hex: "#353535"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var inviteSuggestionsView: some View {
        let normalizedQuery = SearchDataHelper.normalizeQuery(searchText.replacingOccurrences(of: "@", with: ""))

        if !normalizedQuery.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                if suggestionViewModel.isLoading {
                    HStack(spacing: 10) {
                        ProgressView()
                            .tint(.white)
                        Text("Kullanıcılar aranıyor...")
                            .font(.manrope(.medium, size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                } else if !filteredSuggestionPeople.isEmpty {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(filteredSuggestionPeople.prefix(5)) { person in
                                InviteSuggestionRow(person: person) {
                                    let username = normalizedUsername(person.username)
                                    searchText = username
                                    selectedSuggestionUsername = username
                                    viewModel.inviteErrorMessage = nil
                                    viewModel.inviteSuccessMessage = nil
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 260)
                }
            }
            .padding(8)
            .background(Color(hex: "#1B1B1B"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private var filteredSuggestionPeople: [FavoriteStreamer] {
        suggestionViewModel.people.filter {
            !viewModel.isCurrentUser(username: $0.username)
        }
    }
}

private struct InviteSuggestionRow: View {
    let person: FavoriteStreamer
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                avatar
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name)
                        .font(.manrope(.bold, size: 14))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(person.username)
                        .font(.manrope(.medium, size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.branding)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(hex: "#2C2C2C"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var avatar: some View {
        if let url = URL(string: person.imageName), url.scheme != nil {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty, .failure:
                    fallbackAvatar
                @unknown default:
                    fallbackAvatar
                }
            }
        } else {
            fallbackAvatar
        }
    }

    private var fallbackAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFill()
            .foregroundColor(.grayLight)
    }
}

struct InviteView_Previews: PreviewProvider {
    static var previews: some View {
        InviteView(viewModel: ChatViewModel())
            .preferredColorScheme(.dark)
    }
}
