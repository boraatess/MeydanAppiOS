import SwiftUI

struct BirthdayView: View {
    @StateObject var viewModel: BirthdayViewModel
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack {
                    Image("meydan_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    HStack {
                        Button(action: viewModel.navigateBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Geri")
                        .disabled(viewModel.isLoading)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 40)
                
                Spacer()
                
                VStack(spacing: 32) {
                    Text("Üyeliğinizi tamamlamak için lütfen doğum gününüzü giriniz.")
                        .font(.manrope(.medium, size: 18))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Dropdown Selectors
                    HStack(spacing: 12) {
                        
                        // Day
                        BirthdaySelector(title: viewModel.selectedDay == nil ? "Gün" : "\(viewModel.selectedDay!)", width: 80) {
                            ForEach(viewModel.days, id: \.self) { day in
                                Button("\(day)") { viewModel.selectedDay = day }
                            }
                        }
                        
                        // Month
                        BirthdaySelector(title: viewModel.selectedMonth == nil ? "Ay" : viewModel.months[viewModel.selectedMonth! - 1], width: 100) {
                            ForEach(1...12, id: \.self) { month in
                                Button(viewModel.months[month-1]) { viewModel.selectedMonth = month }
                            }
                        }
                        
                        // Year
                        BirthdaySelector(title: viewModel.selectedYear == nil ? "Yıl" : String(viewModel.selectedYear!), width: 90) {
                            ForEach(viewModel.years, id: \.self) { year in
                                Button(String(year)) { viewModel.selectedYear = year }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.manrope(.regular, size: 12))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 18)
                            .frame(height: 30)
                        
                    } else {
                        Spacer().frame(height: 30)
                    }
                    
                    PrimaryButton(title: "Devam") {
                        Task {
                            await viewModel.submitRegister()
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 80)
                
                Spacer()
            }
            .blur(radius: viewModel.isLoading ? 2 : 0)
        }
        .navigationBarHidden(true)
        .loadingOverlay(isPresented: $viewModel.isLoading, message: "İşlem yapılıyor...")
    }
}

struct BirthdaySelector<Content: View>: View {
    let title: String
    let width: CGFloat
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Menu {
            content()
        } label: {
            HStack {
                Text(title)
                    .font(.manrope(.medium, size: 16))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .frame(width: width, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}

#Preview {
    BirthdayView(viewModel: BirthdayViewModel(
        authService: AuthService(),
        authManager: AuthenticationManager(),
        authFlowState: AuthenticationFlowState(),
        appFlowState: AppFlowState(),
        registrationData: RegisterRequest(fullName: "Test User", username: "testuser", email: "test@test.com", password: "Password1", birthday: nil)
    ))
    .preferredColorScheme(.dark)
}
