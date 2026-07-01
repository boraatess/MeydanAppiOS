import SwiftUI

struct InterestsView: View {
    
    @StateObject private var viewModel: InterestsViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var appFlowState: AppFlowState
    
    init(viewModel: InterestsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ScrollView {
                    Image("meydan_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48)
                    
                    Spacer(minLength: 48)
                    
                    // Başlık ve alt başlık
                    InterestsHeaderView(
                        title: "İlgi Alanların Neler?",
                        subtitle: "Sana özel bir deneyim sunabilmemiz için en az 3 konu seç."
                    )
                    
                    InterestsFlowView(
                        interests: viewModel.interests,
                        selectedInterests: $viewModel.selectedInterests,
                        onSelect: viewModel.toggleInterestSelection
                    )
                    
                    Spacer()
                }
                
                PrimaryButton(title: "Devam") {
                    Task {
                        await viewModel.submitSelectedInterests(authManager: authManager)
                        viewModel.completeOnboarding()
                    }
                }
                .disabled(viewModel.selectedInterests.count < 3)
                .opacity(viewModel.selectedInterests.count < 3 ? 0.5 : 1)
            }
            
            // Custom top-left back button overlay
            VStack {
                HStack {
                    Button(action: {
                        TokenStorage.shared.clear()
                        authManager.logout()
                        appFlowState.navigate(to: .auth)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Geri")
                        }
                        .foregroundColor(.white)
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding(.top, 12)
            .padding(.leading, 12)
            .ignoresSafeArea(.keyboard)
        }
        .loadingOverlay(isPresented: $viewModel.isLoading, message: "İlgi alanları yükleniyor…")
    }
}


// MARK: - Alt View'lar

private struct InterestsHeaderView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.manrope(.bold, size: 20))
                .foregroundColor(.brandingLight)
            
            Text(subtitle)
                .font(.manrope(.medium, size: 16))
                .foregroundColor(.gray)
        }
    }
}

private struct InterestsFlowView: View {
    let interests: [Interest]
    @Binding var selectedInterests: Set<Interest>
    let onSelect: (Interest) -> Void
    
    var body: some View {
            FlowLayout(data: interests) { interest in
                Button(action: {
                    withAnimation(.easeInOut) {
                        onSelect(interest)
                    }
                }) {
                    Text(interest.name)
                        .font(.manrope(.bold, size: 16))
                        .foregroundColor(selectedInterests.contains(interest) ? .white : .whiteLight)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if selectedInterests.contains(interest) {
                                    RoundedRectangle(cornerRadius: 9).fill(interest.color)
                                } else {
                                    RoundedRectangle(cornerRadius: 9).stroke(.grayMedium, lineWidth: 1.5)
                                }
                            }
                        )
                }
            }
            .padding(.top)
    }
}


#Preview {
    InterestsView(viewModel: InterestsViewModel(appFlowState: AppFlowState()))
}

