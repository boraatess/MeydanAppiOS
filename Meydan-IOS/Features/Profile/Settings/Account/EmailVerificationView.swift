import SwiftUI

struct EmailVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    let email: String
    @State private var code = ["", "", "", ""]
    @State private var timeLeft = 180
    @FocusState private var focusedField: Int?
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
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
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Timer Section
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(timeLeft) / 180)
                        .stroke(Color.branding, lineWidth: 4)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(timeLeft)")
                        .font(.manrope(.bold, size: 24))
                        .foregroundColor(.white)
                }
                .padding(.top, 40)
                .onReceive(timer) { _ in
                    if timeLeft > 0 {
                        timeLeft -= 1
                    }
                }
                
                Text("Doğrulama kodunu e-posta adresine gönderdik. Lütfen e-postanı kontrol ederek kodu aşağıya gir.")
                    .font(.manrope(.medium, size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 32)
                
                // Code Input
                HStack(spacing: 12) {
                    ForEach(0..<4) { index in
                        TextField("", text: $code[index])
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.manrope(.bold, size: 24))
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == index ? Color.branding : Color.clear, lineWidth: 1)
                            )
                            .focused($focusedField, equals: index)
                            .onChange(of: code[index]) { newValue in
                                if newValue.count > 1 {
                                    code[index] = String(newValue.last!)
                                }
                                if !newValue.isEmpty && index < 3 {
                                    focusedField = index + 1
                                }
                            }
                    }
                }
                .padding(.top, 32)
                
                Button {
                    // Verification logic
                } label: {
                    Text("Kodu Onayla")
                        .font(.manrope(.bold, size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.branding)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                
                HStack(spacing: 4) {
                    Text("Kod gelmedi mi?")
                        .font(.manrope(.medium, size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Button {
                        timeLeft = 180
                        // Resend logic
                    } label: {
                        Text("Tekrar gönder.")
                            .font(.manrope(.bold, size: 12))
                            .foregroundColor(.branding)
                    }
                }
                .padding(.top, 24)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            focusedField = 0
        }
    }
}

#Preview {
    EmailVerificationView(email: "test@example.com")
        .preferredColorScheme(.dark)
}
