import Foundation
import SwiftUI

@MainActor
class BirthdayViewModel: ObservableObject {
    @Published var selectedDay: Int? { didSet { checkAge() } }
    @Published var selectedMonth: Int? { didSet { checkAge() } }
    @Published var selectedYear: Int? { didSet { checkAge() } }
    
    private func checkAge() {
        guard let day = selectedDay, let month = selectedMonth, let year = selectedYear else { return }
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        
        guard let birthDate = calendar.date(from: components) else { return }
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        let age = ageComponents.year ?? 0
        
        if age < 15 {
            errorMessage = "Uygulamamızı yalnızca 15 yaş ve üzerindeki kişiler kullanabilir!"
        } else {
            errorMessage = nil
        }
    }
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let days = Array(1...31)
    let months = [
        "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
        "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ]
    let years: [Int] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 100...currentYear).reversed())
    }()
    
    
    // Dependencies
    private let authService: AuthServiceProtocol
    private let authManager: AuthenticationManager
    private let authFlowState: AuthenticationFlowState
    private let appFlowState: AppFlowState
    
    var registrationData: RegisterRequest?
    
    init(authService: AuthServiceProtocol, 
         authManager: AuthenticationManager, 
         authFlowState: AuthenticationFlowState, 
         appFlowState: AppFlowState, 
         registrationData: RegisterRequest? = nil) {
        self.authService = authService
        self.authManager = authManager
        self.authFlowState = authFlowState
        self.appFlowState = appFlowState
        self.registrationData = registrationData
    }
    
    func submitRegister() async {
        guard let day = selectedDay, let month = selectedMonth, let year = selectedYear else {
            errorMessage = "Lütfen tüm alanları doldurun."
            return
        }
        
        // Age validation
        let calendar = Calendar.current
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        
        guard let birthDate = calendar.date(from: components) else {
            errorMessage = "Geçersiz tarih."
            return
        }
        
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        let age = ageComponents.year ?? 0
        
        if age < 15 {
            errorMessage = "Uygulamamızı yalnızca 15 yaş ve üzerindeki kişiler kullanabilir!"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Format date to ISO string (YYYY-MM-DD)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: birthDate)
        
        do {
            if var data = registrationData {
                // CASE 1: New user registration
                data.birthday = dateString
                let response = try await authService.register(request: data)
                
                if let token = response.token, !token.isEmpty {
                    authManager.login(token: token)
                    
                    // Fetch profile to check state
                    let me = try await AuthService().getMe()
                    let user = me.user
                    
                    if !(user.confirmed ?? false) {
                        authFlowState.navigate(to: .activationOTP(email: data.email))
                    } else if (user.profile?.hobbies ?? []).isEmpty {
                        appFlowState.navigate(to: .interests)
                    } else {
                        appFlowState.navigate(to: .main)
                    }
                } else {
                    // Token gelmediyse aktivasyon sayfasına yönlendir
                    authFlowState.navigate(to: .activationOTP(email: data.email))
                }
            } else {
                // CASE 2: Existing user profile completion
                
                /*
                let request = UpdateBirthDateRequest(profile: .init(birthDate: dateString))
                _ = try await authService.updateBirthDate(request: request)
                */
                
                // After update, check next steps
                let me = try await AuthService().getMe()
                if (me.user.profile?.hobbies ?? []).isEmpty {
                    appFlowState.navigate(to: .interests)
                } else {
                    appFlowState.navigate(to: .main)
                }
            }
        } catch let error as NetworkError {
            if case .serverError(let msg) = error {
                errorMessage = msg
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = "İşlem sırasında bir hata oluştu."
        }
        
        isLoading = false
    }
}
