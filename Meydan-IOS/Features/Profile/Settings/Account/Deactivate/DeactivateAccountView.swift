import SwiftUI

struct DeactivateAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step: Int = 1
    @State private var password = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            // İçerik tam ortada
            VStack {
                if step == 1 {
                    DeactivateConfirmationStep(onYes: { step = 2 }, onNo: { dismiss() })
                } else if step == 2 {
                    DeactivatePasswordStep(password: $password, onConfirm: { step = 3 }, isFocused: _isFocused)
                } else {
                    DeactivateFinalStep(onClose: { dismiss() })
                }
            }
            .padding(.top, 64) // Header üstüne binmesin diye güvenlik boşluğu
            
            // Header (En üstte)
            VStack {
                HStack(spacing: 16) {
                    Button {
                        if step == 1 { dismiss() } else if step == 2 { step = 1 } else { dismiss() }
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
                    
                    Text("Hesabı Devre Dışı Bırak")
                        .font(.manrope(.bold, size: 20))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 20) // Safe Area içi boşluk
                
                Spacer()
            }
            
            
            
        }
        .navigationBarHidden(true)
    }
}

private struct DeactivateConfirmationStep: View {
    let onYes: () -> Void
    let onNo: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Hesabınızı devre dışı bırakmak istediğinizden emin misin?")
                .font(.manrope(.medium, size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                Button(action: onYes) {
                    Text("Evet")
                        .font(.manrope(.bold, size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Button(action: onNo) {
                    Text("Hayır")
                        .font(.manrope(.bold, size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
        }
        
    }
}

private struct DeactivatePasswordStep: View {
    @Binding var password: String
    let onConfirm: () -> Void
    @State private var isSecure = true
    @FocusState var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Hesabınızı devre dışı bırakmak için parolanızı giriniz!")
                .font(.manrope(.medium, size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal, 24)
            
            ZStack(alignment: .trailing) {
                if isSecure {
                    SecureField("************", text: $password)
                        .focused($isFocused)
                } else {
                    TextField("************", text: $password)
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
            
            Button(action: onConfirm) {
                Text("Onayla")
                    .font(.manrope(.bold, size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(password.isEmpty ? Color.white.opacity(0.1) : Color.branding)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .disabled(password.isEmpty)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

private struct DeactivateFinalStep: View {
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 32) {
                Image("error")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                
                VStack(spacing: 16) {
                    Text("Aramızdan ayrıldığın için üzgünüz.")
                        .font(.manrope(.bold, size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Hesabınıza dilediğiniz zaman e-posta adresinle giriş yaparak hesabını yeniden aktifleştirebilirsin.")
                        .font(.manrope(.medium, size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.05))
            )
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    DeactivateAccountView()
        .preferredColorScheme(.dark)
}
