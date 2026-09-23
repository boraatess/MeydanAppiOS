import SwiftUI

struct PollResultsView: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Anket Sonucu")
                    .font(.manrope(.bold, size: 20))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { 
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        viewModel.showPollResultsSheet = false 
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
            
            VStack(alignment: .leading, spacing: 24) {
                Text(viewModel.activePollQuestion)
                    .font(.manrope(.bold, size: 18))
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    ForEach(0..<viewModel.activePollOptions.count, id: \.self) { index in
                        let percentage = viewModel.getPercentage(for: index)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack(alignment: .leading) {
                                // Background bar
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "#2C2C2C"))
                                    .frame(height: 56)
                                
                                // Result bar
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(resultBarColor(for: index).opacity(0.6))
                                    .frame(width: CGFloat(percentage) / 100 * (UIScreen.main.bounds.width - 48), height: 56)
                                
                                HStack {
                                    Text(viewModel.activePollOptions[index])
                                        .font(.manrope(.medium, size: 16))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("%\(percentage)")
                                        .font(.manrope(.bold, size: 16))
                                        .foregroundColor(.white)
	                                }
	                                .padding(.horizontal, 16)
	                            }
	                        }
	                    }
	                }

                if viewModel.isCurrentUserRoomOwner && viewModel.pollState == .active {
                    Divider()
                        .background(Color.white.opacity(0.12))

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            viewModel.endPoll()
                        }
                    } label: {
                        Text("Anketi Sonlandır")
                            .font(.manrope(.medium, size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "#363636"))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color(hex: "#1B1B1B"))
        .cornerRadius(20)
        .padding(.horizontal, 16)
    }

    private func resultBarColor(for index: Int) -> Color {
        index == 0 ? .branding : Color(red: 0.99, green: 0.54, blue: 0.51)
    }
}
