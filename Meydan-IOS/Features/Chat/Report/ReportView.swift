import SwiftUI

struct ReportView: View {
    @StateObject var viewModel: ReportViewModel
    var onDismiss: () -> Void
    
    init(viewModel: ReportViewModel, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Sohbeti Şikayet Et")
                    .font(.manrope(.bold, size: 20))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { onDismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Sohbeti şikayet etme sebebiniz nedir?")
                        .font(.manrope(.medium, size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 12) {
                        ForEach(viewModel.reasons) { reason in
                            if reason != .other {
                                ReportReasonRow(title: reason.displayText, isSelected: viewModel.selectedReason == reason) {
                                    viewModel.selectReason(reason)
                                }
                            }
                        }
                        
                        // Diğer field
                        TextField("Diğer (yazınız)", text: $viewModel.descriptionText)
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(Color(hex: "#2C2C2C"))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .font(.manrope(.regular, size: 14))
                    }
                    .padding(.horizontal, 24)
                    
                    // Şikayet Et Butonu
                    Button(action: {
                        viewModel.sendReport()
                    }) {
                        Group {
                            if viewModel.isSending {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Şikayet Et")
                                    .font(.manrope(.bold, size: 16))
                            }
                        }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.branding)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.isSending)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
        .background(Color(hex: "#121212"))
        .cornerRadius(24)
        .padding(.horizontal, 16)
        .overlay {
            if viewModel.showSuccessOverlay {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundColor(.branding)

                    Text("Şikayetiniz alındı")
                        .font(.manrope(.bold, size: 18))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#121212"))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .transition(.opacity)
            }
        }
        .alert("Şikayet gönderilemedi", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.showSuccessOverlay) { isVisible in
            guard isVisible else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                onDismiss()
            }
        }
    }
}

private struct ReportReasonRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.branding : Color.white.opacity(0.1))
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Text(title)
                    .font(.manrope(.medium, size: 14))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color(hex: "#2C2C2C"))
            .cornerRadius(12)
        }
    }
}

struct ReportView_User_Previews: PreviewProvider {
    static var previews: some View {
        ReportView(viewModel: ReportViewModel(context: .user(userId: "mock", username: "aylinbilek")), onDismiss: {})
            .preferredColorScheme(.dark)
    }
}

struct ReportView_Stream_Previews: PreviewProvider {
    static var previews: some View {
        ReportView(viewModel: ReportViewModel(context: .stream(roomId: "mock", ownerUsername: "mackolik", streamTitle: "Beşiktaş Maç")), onDismiss: {})
            .preferredColorScheme(.dark)
    }
}
