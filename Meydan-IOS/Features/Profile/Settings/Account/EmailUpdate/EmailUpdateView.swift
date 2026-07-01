import SwiftUI

struct EmailUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EmailUpdateViewModel()
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                             )
                    }
                    
                    Text("E-posta Yenileme")
                        .font(.manrope(.bold, size: 20))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                ZStack {
                    VStack(spacing: 24) {
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.manrope(.medium, size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        if let success = viewModel.successMessage {
                            Text(success)
                                .font(.manrope(.medium, size: 14))
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                        }
                        
                        TextField("Yeni E-Posta", text: $viewModel.newEmail)
                            .font(.manrope(.medium, size: 16))
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.emailAddress)
                            .focused($isFocused)
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        Button {
                            Task {
                                _ = await viewModel.updateEmail()
                            }
                        } label: {
                            ZStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("E-Posta Yenile")
                                        .font(.manrope(.bold, size: 16))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(viewModel.newEmail.isEmpty || viewModel.isLoading ? Color.white.opacity(0.1) : Color.branding)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.newEmail.isEmpty || viewModel.isLoading)
                    }
                    .padding(.horizontal, 24)
                }
                .frame(maxHeight: .infinity)
                
                // Navigation to Verification
                NavigationLink(
                    destination: VerificationCodeView(
                        viewModel: VerificationCodeViewModel(
                            email: viewModel.newEmail,
                            mode: .emailUpdate,
                            authFlowState: AuthenticationFlowState()
                        )
                    ),
                    isActive: $viewModel.navigateToVerification
                ) {
                    EmptyView()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

#Preview {
    EmailUpdateView()
        .preferredColorScheme(.dark)
}
