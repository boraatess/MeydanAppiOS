import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = DeleteAccountViewModel()
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            // İçerik tam ortada
            VStack {
                if viewModel.step == 1 {
                    DeleteConfirmationStep(onYes: { viewModel.step = 2 }, onNo: { dismiss() })
                } else if viewModel.step == 2 {
                    DeletePasswordStep(
                        password: $viewModel.password,
                        isLoading: viewModel.isLoading,
                        errorMessage: viewModel.errorMessage,
                        onConfirm: {
                            Task {
                                await viewModel.deleteAccount()
                            }
                        }
                    )
                } else {
                    DeleteFinalStep(onClose: { dismiss() })
                }
            }
            .padding(.top, 64)
            
            // Header (En üstte)
            VStack {
                HStack(spacing: 16) {
                    Button {
                        if viewModel.step == 1 { dismiss() } 
                        else if viewModel.step == 2 { viewModel.step = 1 } 
                        else { dismiss() }
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
                    
                    Text("Hesabı Sil")
                        .font(.manrope(.bold, size: 20))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

private struct DeleteConfirmationStep: View {
    let onYes: () -> Void
    let onNo: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Hesabınızı silmek istediğinizden emin misin?")
                .font(.manrope(.bold, size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .frame(height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                Button(action: onYes) {
                    Text("Evet")
                        .font(.manrope(.bold, size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Button(action: onNo) {
                    Text("Hayır")
                        .font(.manrope(.bold, size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

private struct DeletePasswordStep: View {
    @Binding var password: String
    let isLoading: Bool
    let errorMessage: String?
    let onConfirm: () -> Void
    @State private var isSecure = true
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Hesabınızı silmek için parolanızı giriniz.")
                .font(.manrope(.bold, size: 18))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .frame(height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal, 24)
            
            VStack(spacing: 8) {
                ZStack(alignment: .trailing) {
                    if isSecure {
                        SecureField("", text: $password)
                    } else {
                        TextField("", text: $password)
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
                
                if let error = errorMessage {
                    Text(error)
                        .font(.manrope(.medium, size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 32)
                }
            }
            
            Button(action: onConfirm) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Onayla ve Sil")
                            .font(.manrope(.bold, size: 18))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(password.isEmpty || isLoading ? Color.branding.opacity(0.5) : Color.branding)
                .cornerRadius(12)
            }
            .disabled(password.isEmpty || isLoading)
            .padding(.horizontal, 24)
        }
    }
}

/*
 Aramızdan ayrıldığın için üzgünüz.  Hesabın 15 gün sonra tamamen silinecek.
  
 Dilersen, 15 gün içinde kullanıcı adın veya e-posta adresinle giriş yaparak hesabını yeniden aktifleştirebilirsin.
 
 */

private struct DeleteFinalStep: View {
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                Image("error")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                
                VStack(spacing: 16) {
                    Text("Aramızdan ayrıldığın için üzgünüz. Hesabın 15 gün sonra tamamen silinecek.")
                        .font(.manrope(.bold, size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Dilersen, 15 gün içinde kullanıcı adın veya e-posta adresinle giriş yaparak hesabını yeniden aktifleştirebilirsin.")
                        .font(.manrope(.medium, size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.05))
            )
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    DeleteAccountView()
        .preferredColorScheme(.dark)
}
