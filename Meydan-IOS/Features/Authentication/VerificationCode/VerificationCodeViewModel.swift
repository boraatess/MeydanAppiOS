import Foundation
import Combine

@MainActor
class VerificationCodeViewModel: ObservableObject {
    enum Mode {
        case resetPassword
        case activateAccount
        case emailUpdate
    }
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    private let authFlowState: AuthenticationFlowState
    private let authService: AuthServiceProtocol
    
    @Published var timeRemaining: Int = 180
    @Published var progress: Double = 1.0
    private var timer: AnyCancellable?
    private let totalTime: Int = 180
    
    // Girilen doğrulama kodu
    @Published var code: String = ""
    @Published var verificationSucceeded: Bool = false
    @Published var timerExpired: Bool = false
    
    let email: String
    let userId: String?
    let password: String? // Added for emailUpdate
    let mode: Mode
    
    init(email: String, userId: String? = nil, password: String? = nil, mode: Mode = .activateAccount, authFlowState: AuthenticationFlowState, authService: AuthServiceProtocol = AuthService()) {
        self.email = email
        self.userId = userId
        self.password = password
        self.mode = mode
        self.authFlowState = authFlowState
        self.authService = authService
        startTimer()
    }

    func checkVerificationStatus() async {
        isLoading = true
        errorMessage = nil

        guard code.count == 4 else {
            isLoading = false
            errorMessage = "Lütfen 4 haneli kodu giriniz."
            return
        }

        do {
            switch mode {
            case .resetPassword:
                // Kod doğrulanır ve geçici resetToken alınır, sonra ResetPassword ekranına geçilir
                let request = VerifyResetCodeRequest(code: code)
                let response = try await authService.verifyResetCode(request: request)
                self.isLoading = false
                if response.isSuccess, let token = response.resetToken, !token.isEmpty {
                    self.authFlowState.navigate(to: .resetPassword(email: self.email, token: token))
                } else {
                    self.errorMessage = response.message ?? "Kod hatalı veya süresi dolmuş."
                }
            case .activateAccount:
                guard let userId = userId else {
                    isLoading = false
                    errorMessage = "Kullanıcı bilgisi eksik. Lütfen tekrar deneyin."
                    return
                }
                let request = ConfirmMailRequest(userId: userId, code: code)
                let response = try await authService.confirmMail(request: request)
                self.isLoading = false
                if response.status.lowercased() == "ok" {
                    self.verificationSucceeded = true
                    self.authFlowState.navigate(to: .activationSuccess(email: self.email))
                } else {
                    self.errorMessage = response.message
                }
            case .emailUpdate:
                let request = VerifyEmailUpdateRequest(code: code, newEmail: email)
                _ = try await authService.verifyEmailUpdate(request: request)
                self.isLoading = false
                self.verificationSucceeded = true
            }
        } catch let error as NetworkError {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        } catch {
            self.isLoading = false
            self.errorMessage = "Beklenmedik bir hata oluştu."
        }
    }
    
    func resendLink() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                switch mode {
                case .resetPassword:
                    let request = ForgotPasswordRequest(email: email)
                    _ = try await authService.forgotPassword(request: request)
                case .activateAccount:
                    let request = ResendConfirmMailRequest(email: email)
                    _ = try await authService.resendConfirmMail(request: request)
                case .emailUpdate:
                    let request = RequestEmailUpdateRequest(newEmail: email)
                    _ = try await authService.requestEmailUpdate(request: request)
                }

                // Sayaç ve UI’ı sıfırla
                code = ""
                timeRemaining = totalTime
                progress = 1.0
                startTimer()
            } catch let error as NetworkError {
                errorMessage = error.localizedDescription
            } catch {
                errorMessage = "Beklenmedik bir hata oluştu."
            }
            isLoading = false
        }
    }
    
    private func startTimer() {
        timer?.cancel()
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    self.progress = Double(self.timeRemaining) / Double(self.totalTime)
                } else {
                    self.timer?.cancel()
                    self.timerExpired = true
                }
            }
    }
}

