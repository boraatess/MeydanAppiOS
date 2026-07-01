import SwiftUI

struct PasswordRenewalView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PasswordRenewalViewModel()
    @State private var showSuccessPopup = false
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    Button {
                        if viewModel.step == 1 { dismiss() } else { viewModel.step = 1 }
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
                    
                    Text("Parola Yenileme")
                        .font(.manrope(.bold, size: 20))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 32)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.manrope(.medium, size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }
                
                Spacer()
                
                if viewModel.step == 1 {
                    Step1View(
                        password: $viewModel.currentPassword,
                        isLoading: viewModel.isLoading,
                        onNext: {
                            Task {
                                await viewModel.checkCurrentPassword()
                            }
                        }
                    )
                } else {
                    Step2View(
                        newPassword: $viewModel.newPassword,
                        confirmPassword: $viewModel.confirmPassword,
                        hasMinLength: viewModel.hasMinLength,
                        hasUpperLowerCase: viewModel.hasUpperLowerCase,
                        hasNumber: viewModel.hasNumber,
                        isFormValid: viewModel.isNewPasswordValid && viewModel.newPassword == viewModel.confirmPassword,
                        onPasswordChange: {
                            viewModel.updateValidation()
                        },
                        isLoading: viewModel.isLoading,
                        onComplete: {
                            Task {
                                if await viewModel.updatePassword() {
                                    showSuccessPopup = true
                                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                                    dismiss()
                                }
                            }
                        }
                    )
                }
                
                Spacer()
            }

            if showSuccessPopup {
                SuccessPopupView()
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.2), value: showSuccessPopup)
    }
}

private struct Step1View: View {
    @Binding var password: String
    let isLoading: Bool
    let onNext: () -> Void
    @State private var isSecure = true
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Parolanızı yenilemek için mevcut şifrenizi giriniz.")
                .font(.manrope(.medium, size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            ZStack(alignment: .trailing) {
                if isSecure {
                    SecureField("Parola", text: $password)
                        .focused($isFocused)
                } else {
                    TextField("Parola", text: $password)
                        .focused($isFocused)
                }
                
                Button {
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.trailing, 16)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            .padding(.horizontal, 24)
            .foregroundColor(.white)
            
            Button(action: onNext) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Gönder")
                            .font(.manrope(.bold, size: 18))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(password.isEmpty || isLoading ? Color.white.opacity(0.1) : Color.branding)
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .disabled(password.isEmpty || isLoading)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

private struct Step2View: View {
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    let hasMinLength: Bool
    let hasUpperLowerCase: Bool
    let hasNumber: Bool
    let isFormValid: Bool
    let onPasswordChange: () -> Void
    let isLoading: Bool
    let onComplete: () -> Void
    @FocusState private var focusedField: Int?
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                PasswordField(title: "Yeni Parola", text: $newPassword)
                    .focused($focusedField, equals: 0)
                    .onChange(of: newPassword) { _ in
                        onPasswordChange()
                    }
                PasswordField(title: "Yeni Parola Tekrar", text: $confirmPassword)
                    .focused($focusedField, equals: 1)
            }
            .padding(.horizontal, 24)
            
            VStack(alignment: .leading, spacing: 10) {
                ValidationItem(text: "En az 8 karakter olmalı.", isValid: hasMinLength)
                ValidationItem(text: "En az 1 büyük harf ve küçük harf olmalı.", isValid: hasUpperLowerCase)
                ValidationItem(text: "En az 1 rakam olmalı.", isValid: hasNumber)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: onComplete) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Parolayı Yenile")
                            .font(.manrope(.bold, size: 18))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(!isFormValid || confirmPassword.isEmpty || isLoading ? Color.white.opacity(0.1) : Color.branding)
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .disabled(!isFormValid || confirmPassword.isEmpty || isLoading)
        }
        .onAppear {
            onPasswordChange()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = 0
            }
        }
    }
}

private struct PasswordField: View {
    let title: String
    @Binding var text: String
    @State private var isSecure = true
    
    var body: some View {
        ZStack(alignment: .trailing) {
            if isSecure {
                SecureField(title, text: $text)
            } else {
                TextField(title, text: $text)
            }
            
            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.trailing, 16)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .foregroundColor(.white)
    }
}

private struct ValidationItem: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isValid ? Color.green : Color.white.opacity(0.4))
                .frame(width: 8, height: 8)
            Text(text)
                .font(.manrope(.medium, size: 14))
                .foregroundColor(isValid ? .white : .white.opacity(0.6))
        }
    }
}

private struct SuccessPopupView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.green)

            Text("Basarili")
                .font(.manrope(.bold, size: 18))
                .foregroundColor(.white)

            Text("Sifreniz guncellendi.")
                .font(.manrope(.medium, size: 14))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 20)
    }
}

#Preview {
    PasswordRenewalView()
        .preferredColorScheme(.dark)
}
