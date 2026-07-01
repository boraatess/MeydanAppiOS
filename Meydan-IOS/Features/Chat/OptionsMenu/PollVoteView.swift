import SwiftUI

struct PollVoteView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var selectedOption: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Anket")
                    .font(.manrope(.bold, size: 20))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { 
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        viewModel.showPollVoteSheet = false 
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 14)
            .padding(.bottom, 22)
            
            VStack(alignment: .leading, spacing: 20) {
                Text(viewModel.activePollQuestion)
                    .font(.manrope(.medium, size: 20))
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    ForEach(0..<viewModel.activePollOptions.count, id: \.self) { index in
                        Button(action: { selectedOption = index }) {
                            HStack {
                                Text(viewModel.activePollOptions[index])
                                    .font(.manrope(.medium, size: 16))
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 56)
                            .background(selectedOption == index ? Color.branding.opacity(0.2) : Color(hex: "#363636"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedOption == index ? Color.branding : Color.clear, lineWidth: 1)
                            )
                            .foregroundColor(.white)
                        }
                    }
                }
                
                Button(action: {
                    if let index = selectedOption {
                        viewModel.vote(optionIndex: index)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            viewModel.showPollVoteSheet = false
                        }
                    }
                }) {
                    Text("Gönder")
                        .font(.manrope(.bold, size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(selectedOption != nil ? Color.branding : Color.gray)
                        .cornerRadius(16)
                }
                .disabled(selectedOption == nil)
                .padding(.top, 8)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .padding(0)
        .background(Color(hex: "#1B1B1B"))
        .cornerRadius(18)
        .padding(.horizontal, 34)
    }
}
