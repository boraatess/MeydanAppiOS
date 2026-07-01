import SwiftUI

struct ResetPasswordView: View {
    @StateObject var viewModel: ResetPasswordViewModel
    @EnvironmentObject var authFlowState: AuthenticationFlowState
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            if viewModel.isSuccess {
                ActivationSuccessView(mode: .resetPassword(email: viewModel.email))
            } else {
                PasswordEntryView(viewModel: viewModel)
            }
        }
        .navigationBarHidden(true)
        
    }
    
}

// MARK: - Parola Giriş View
private struct PasswordEntryView: View {
    @ObservedObject var viewModel: ResetPasswordViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Back Button at Top Left
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image("Arrow - Left")
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .padding(12)
                        .background(Color.grayDark)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Spacer()
            }
            .padding(.top, 8)
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 0) {
                Image("meydan_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .padding(.bottom, 48)

                VStack(spacing: 16) {
                    AuthTextField(
                        placeholder: "Yeni Parola",
                        text: $viewModel.newPassword,
                        isSecure: true,
                        errorMessage: (!viewModel.confirmPassword.isEmpty && viewModel.newPassword != viewModel.confirmPassword) ? "" : nil
                    )
                    .onChange(of: viewModel.newPassword) { _ in viewModel.updateValidation() }
                    
                    AuthTextField(
                        placeholder: "Yeni Parola Tekrar",
                        text: $viewModel.confirmPassword,
                        isSecure: true,
                        errorMessage: (!viewModel.confirmPassword.isEmpty && viewModel.newPassword != viewModel.confirmPassword) ? "Parolalar eşleşmiyor. Lütfen tekrar kontrol edin." : nil
                    )
                    .onChange(of: viewModel.confirmPassword) { _ in viewModel.updateValidation() }
                }

                // Validation Rules List
                VStack(alignment: .leading, spacing: 8) {
                    ValidationRow(
                        text: "En az 8 karakter olmalı.",
                        isMet: viewModel.hasMinLength,
                        isEmpty: viewModel.newPassword.isEmpty
                    )
                    ValidationRow(
                        text: "En az 1 büyük harf ve küçük harf olmalı.",
                        isMet: viewModel.hasUpperLowerCase,
                        isEmpty: viewModel.newPassword.isEmpty
                    )
                    ValidationRow(
                        text: "En az 1 rakam olmalı.",
                        isMet: viewModel.hasNumber,
                        isEmpty: viewModel.newPassword.isEmpty
                    )
                }
                .padding(.top, 16)
                .padding(.leading, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                PrimaryButton(
                    title: "Parolayı Yenile",
                    isLoading: viewModel.isLoading
                ) {
                    Task { await viewModel.resetPassword() }
                }
                .padding(.top, 32)
                .disabled(!viewModel.isFormValid)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

fileprivate struct ValidationRow: View {
    let text: String
    let isMet: Bool
    let isEmpty: Bool
    
    var iconName: String {
        if isEmpty { return "exclamationmark.circle.fill" }
        return isMet ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
    }
    
    var iconColor: Color {
        if isEmpty { return .white }
        return isMet ? .green : .redLightError
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
            Text(text)
                .font(.manrope(.medium, size: 12))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ResetPasswordView(viewModel: ResetPasswordViewModel(email: "mehmetfurkansakiz@gmail.com", token: "123456", authFlowState: AuthenticationFlowState()))
}
