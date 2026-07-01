import SwiftUI

struct VerificationCodeView: View {
    @StateObject var viewModel: VerificationCodeViewModel
    @EnvironmentObject var authFlowState: AuthenticationFlowState
    @EnvironmentObject private var appFlowState: AppFlowState
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                
                // Dairesel Zamanlayıcı
                CircularTimerView(progress: viewModel.progress, timeRemaining: viewModel.timeRemaining)
                    .frame(width: 85, height: 85)
                    .padding(.top, 40)
                
                // Başlık ve Açıklama
                Text(viewModel.mode == .resetPassword
                     ? "E-Posta doğrulama kodunu almak için lütfen e- posta adresinizi yazınız."
                     : "Doğrulama kodunu e-posta adresine gönderdik. Lütfen e-postanı kontrol ederek kodu aşağıya gir.")
                    .font(.manrope(.medium, size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // 4 Haneli Kod Giriş Alanı
                OTPCodeField(code: $viewModel.code, length: 4, isEnabled: !viewModel.timerExpired)
                    .onChange(of: viewModel.code) { newCode in
                        if newCode.count == 4 {
                            Task { await viewModel.checkVerificationStatus() }
                        }
                    }
                    .onChange(of: viewModel.verificationSucceeded) { succeeded in
                        if succeeded && viewModel.mode == .emailUpdate {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .onChange(of: viewModel.timerExpired) { expired in
                        if expired {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                
                // Onay Butonu
                PrimaryButton(
                    title: "Kodu Onayla",
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.code.count != 4 || viewModel.timerExpired
                ) {
                    Task { await viewModel.checkVerificationStatus() }
                }
                .padding(.horizontal, 16)
                .disabled(viewModel.timerExpired)
                
                // Yeniden Gönder Butonu
                Button(action: {
                    viewModel.resendLink()
                }) {
                    HStack(spacing: 4) {
                        Text("Kod gelmedi mi?")
                            .font(.manrope(.light, size: 12))
                        Text("Tekrar gönder.")
                            .font(.manrope(.medium, size: 12))
                            .foregroundColor(.redError)
                    }
                }
                .disabled(viewModel.timeRemaining > 0)
                .foregroundColor(viewModel.timeRemaining > 0 ? .grayMedium : .whiteLight)
                
                // Hata Mesajı
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if viewModel.mode == .activateAccount {
                        TokenStorage.shared.clear()
                        authManager.logout()
                        appFlowState.navigate(to: .auth)
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

// 4 haneli OTP/Doğrulama kodu bileşeni
struct OTPCodeField: View {
    @Binding var code: String
    var length: Int = 4
    var isEnabled: Bool = true
    @FocusState private var isFocused: Bool
    
    private let boxSize: CGFloat = 56
    private let cornerRadius: CGFloat = 12
    
    var body: some View {
        ZStack {
            HStack(spacing: 12) {
                ForEach(0..<length, id: \.self) { index in
                    let char = character(at: index)
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.grayLight.opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(borderColor(for: index), lineWidth: 1.5)
                            )
                        
                        Text(char)
                            .font(.manrope(.bold, size: 24))
                            .foregroundColor(.whiteLight)
                    }
                    .frame(width: boxSize, height: boxSize)
                }
            }
            
            // Gizli TextField: gerçek giriş burada yapılır
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .foregroundColor(.clear)
                .accentColor(.clear)
                .disableAutocorrection(true)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit { isFocused = false }
                .onChange(of: code) { newValue in
                    // Sadece rakam, maksimum length
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count > length {
                        code = String(filtered.prefix(length))
                    } else {
                        code = filtered
                    }
                    // 4 haneye ulaşınca klavyeyi kapat
                    if code.count == length {
                        isFocused = false
                    }
                }
                .frame(width: 0, height: 0)
                .opacity(0.01)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isEnabled { isFocused = true }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
    
    private func character(at index: Int) -> String {
        guard index < code.count else { return "" }
        let i = code.index(code.startIndex, offsetBy: index)
        return String(code[i])
    }
    
    private func borderColor(for index: Int) -> Color {
        // Odaklanılan kutuya vurgu
        return index == min(code.count, length - 1) ? .branding : .grayMedium.opacity(0.18)
    }
}

struct CircularTimerView: View {
    let progress: Double
    let timeRemaining: Int
    
    var body: some View {
        ZStack {
            // Arka plan dairesi
            Circle()
                .stroke(lineWidth: 4)
                .foregroundColor(Color.white.opacity(0.1))
            
            // İlerleme dairesi
            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .foregroundColor(.branding)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
            
            // Ortadaki saniye metni
            Text("\(timeRemaining)")
                .font(.manrope(.bold, size: 24))
                .foregroundColor(.whiteLight)
        }
    }
}

#Preview {
    VerificationCodeView(
        viewModel: VerificationCodeViewModel(
            email: "mehmetfurkansakiz@gmail.com",
            mode: .activateAccount,
            authFlowState: AuthenticationFlowState()
        )
    )
}


