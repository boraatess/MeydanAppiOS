import SwiftUI

struct ParticipantsView: View {
    @ObservedObject var viewModel: ChatViewModel
    var onParticipantTap: (Participant) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Katılımcılar")
                    .font(.manrope(.bold, size: 20))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        viewModel.showParticipantsSheet = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Katılımcı Listesi
            Group {
                if viewModel.isLoadingParticipants {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else if let errorMessage = viewModel.participantsErrorMessage {
                    VStack(spacing: 12) {
                        Spacer()
                        Text(errorMessage)
                            .font(.manrope(.medium, size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Tekrar Dene") {
                            viewModel.loadParticipants()
                        }
                        .font(.manrope(.semiBold, size: 14))
                        .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                } else if viewModel.participants.isEmpty {
                    VStack {
                        Spacer()
                        Text("Henüz katılımcı yok.")
                            .font(.manrope(.medium, size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(viewModel.participants) { participant in
                                ParticipantRow(participant: participant) {
                                    onParticipantTap(participant)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }
                }
            }
            .frame(maxHeight: 360)
            
            // Bottom Chevron
            Image(systemName: "chevron.down")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 20)
        }
        .background(Color(hex: "#121212"))
        .cornerRadius(24)
        .padding(.horizontal, 16)
        .onAppear {
            viewModel.loadParticipants()
        }
    }
}

struct ParticipantRow: View {
    let participant: Participant
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                participantAvatar

                HStack(spacing: 4) {
                    Text(participant.name)
                        .font(.manrope(.bold, size: 16))
                        .foregroundColor(.white)

                    if !participant.username.isEmpty {
                        Text("@\(participant.username)")
                            .font(.manrope(.regular, size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "#2C2C2C"))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var participantAvatar: some View {
        if let avatar = participant.avatar,
           !avatar.isEmpty,
           let url = URL(string: avatar) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.gray)
                .background(Color.white)
                .clipShape(Circle())
        }
    }
}

struct Participant: Identifiable, Hashable {
    let id: String
    let userId: String
    let name: String
    let username: String
    let avatar: String?
}

struct Participant_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantsView(viewModel: ChatViewModel())
            .preferredColorScheme(.dark)
    }
}
