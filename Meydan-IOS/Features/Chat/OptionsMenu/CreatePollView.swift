import SwiftUI

struct CreatePollView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var question: String = ""
    @State private var options: [String] = ["", ""]
    @State private var allowMultipleAnswers: Bool = true
    @FocusState private var focusedField: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Anket Oluştur")
                    .font(.manrope(.bold, size: 20))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { 
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        viewModel.showCreatePollSheet = false 
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
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Soru Alanı
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Anket Sorusu")
                            .font(.manrope(.bold, size: 16))
                            .foregroundColor(.white)
                        
                        TextField("Anket Sorusu", text: $question)
                            .focused($focusedField, equals: 0)
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(Color(hex: "#2C2C2C"))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    
                    // Seçenekler Alanı
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Anket Seçenekleri")
                            .font(.manrope(.bold, size: 16))
                            .foregroundColor(.white)
                        
                        ForEach(0..<options.count, id: \.self) { index in
                            TextField("Seçenek \(index + 1)", text: $options[index])
                                .focused($focusedField, equals: index + 1)
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Color(hex: "#2C2C2C"))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                        
                        // Seçenek Ekle Butonu
                        HStack {
                            Spacer()
                            Button(action: {
                                if options.count < 10 {
                                    options.append("")
                                }
                            }) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                    
                    // Multiple Answers Checkbox
                    Button(action: { allowMultipleAnswers.toggle() }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(allowMultipleAnswers ? Color.branding : Color.white.opacity(0.1))
                                    .frame(width: 20, height: 20)
                                
                                if allowMultipleAnswers {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Text("Birden fazla cevaba izin ver")
                                .font(.manrope(.medium, size: 14))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Gönder Butonu
                    Button(action: {
                        viewModel.startPoll(question: question, options: options)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            viewModel.showCreatePollSheet = false
                        }
                    }) {
                        Text("Gönder")
                            .font(.manrope(.bold, size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.branding)
                            .cornerRadius(12)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
        }
        .background(Color(hex: "#121212"))
        .cornerRadius(24)
        .padding(.horizontal, 16)
    }
}


struct CreatePollView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePollView(viewModel: ChatViewModel())
            .preferredColorScheme(.dark)
    }
}
