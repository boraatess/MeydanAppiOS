import Foundation
import Alamofire
import AuthenticationServices
@preconcurrency import GoogleSignIn

// PROTOKOL: Auth işlemleri için hangi fonksiyonların olması gerektiğini tanımlar.
@MainActor
protocol AuthServiceProtocol {
    func login(request: LoginRequest) async throws -> LoginResponse
    func register(request: RegisterRequest) async throws -> RegisterResponse
    func socialLogin(request: SocialLoginRequest) async throws -> LoginResponse
    func forgotPassword(request: ForgotPasswordRequest) async throws -> Empty
    func verifyResetCode(request: VerifyResetCodeRequest) async throws -> VerifyResetCodeResponse
    func resetPassword(request: ResetPasswordRequest) async throws -> Empty
    func confirmMail(request: ConfirmMailRequest) async throws -> ConfirmMailResponse
    func resendConfirmMail(request: ResendConfirmMailRequest) async throws -> Empty
    func getMe() async throws -> MeResponse
    func updateBirthDate(request: UpdateBirthDateRequest) async throws -> Empty
    func updateProfile(request: UpdateProfileRequest) async throws -> Empty
    func checkPassword(request: CheckPasswordRequest) async throws -> CheckPasswordResponse
    func setPassword(request: SetPasswordRequest) async throws -> Empty
    func updateEmail(request: UpdateEmailRequest) async throws -> Empty
    func requestEmailUpdate(request: RequestEmailUpdateRequest) async throws -> Empty
    func verifyEmailUpdate(request: VerifyEmailUpdateRequest) async throws -> Empty
    func deleteAccount() async throws -> Empty
    func createSupport(request: SupportRequest) async throws -> Empty
}

@MainActor
class AuthService: NSObject, AuthServiceProtocol {
    
    static let shared = AuthService()
    private let baseURL = AppConfig.apiBaseURL
    
    private func buildHeaders() -> HTTPHeaders {
        var headers: HTTPHeaders = ["Content-Type": "application/json"]
        if let token = TokenStorage.shared.token, !token.isEmpty {
            headers.add(name: "Authorization", value: "Bearer \(token)")
        }
        return headers
    }
    
    // MARK: - Normal Login
    func login(request: LoginRequest) async throws -> LoginResponse {
        let url = "\(baseURL)/user/login"
        return try await performRequest(url: url, method: .post, parameters: request)
    }
    
    // MARK: - Register
    func register(request: RegisterRequest) async throws -> RegisterResponse {
        // old -> DEBUG: [POST] https://meydan-backend-1.onrender.com/user/register
        // new -> https://meydan-af935.web.app/api/user/register
        
        let url = "\(baseURL)/user/register"
        return try await performRequest(url: url, method: .post, parameters: request)
    }
    
    // MARK: - Social Login
    func socialLogin(request: SocialLoginRequest) async throws -> LoginResponse {
        let url = "\(baseURL)/user/social-login"
        return try await performRequest(url: url, method: .post, parameters: request)
    }
    
    // MARK: - Forgot / Reset Password
    func forgotPassword(request: ForgotPasswordRequest) async throws -> Empty {
        let url = "\(baseURL)/user/forgot-password"
        return try await performRequest(url: url, method: .post, parameters: request)
    }
    
    func verifyResetCode(request: VerifyResetCodeRequest) async throws -> VerifyResetCodeResponse {
        let url = "\(baseURL)/user/verify-reset-code"
        return try await performRequest(url: url, method: .post, parameters: request)
    }
    
    func resetPassword(request: ResetPasswordRequest) async throws -> Empty {
        let url = "\(baseURL)/user/reset-password"
        return try await performRequest(url: url, method: .post, parameters: request)
    }
    
    // MARK: - Confirm Mail / Resend Confirm Mail
    func confirmMail(request: ConfirmMailRequest) async throws -> ConfirmMailResponse {
        let url = "\(baseURL)/user/confirm-mail"
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    func resendConfirmMail(request: ResendConfirmMailRequest) async throws -> Empty {
        let url = "\(baseURL)/user/resend-confirm-mail"
        return try await performRequest(url: url, method: .post, parameters: request)
    }
    
    // MARK: - Me (Current User)
    func getMe() async throws -> MeResponse {
        let url = "\(baseURL)/user/me"
        return try await performRequest(url: url, method: .get)
    }
    
    // MARK: - PROFİLE UPDATE SERVİCES-
    // MARK: - Update Birth Date
    func updateBirthDate(request: UpdateBirthDateRequest) async throws -> Empty {
        let url = "\(baseURL)/user/me"
        return try await performRequest(url: url, method: .put, parameters: request)
    }
    
    func updateProfile(request: UpdateProfileRequest) async throws -> Empty {
        let url = "\(baseURL)/user/me"
        return try await performRequest(url: url, method: .put, parameters: request)
    }

    func checkPassword(request: CheckPasswordRequest) async throws -> CheckPasswordResponse {
        let url = "\(baseURL)/user/check-password"
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    func setPassword(request: SetPasswordRequest) async throws -> Empty {
        let url = "\(baseURL)/user/set-password"
        return try await performRequest(url: url, method: .put, parameters: request)
    }

    func updateEmail(request: UpdateEmailRequest) async throws -> Empty {
        let url = "\(baseURL)/user/update-email"
        return try await performRequest(url: url, method: .put, parameters: request)
    }

    func requestEmailUpdate(request: RequestEmailUpdateRequest) async throws -> Empty {
        let url = "\(baseURL)/user/request-email-update"
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    func verifyEmailUpdate(request: VerifyEmailUpdateRequest) async throws -> Empty {
        let url = "\(baseURL)/user/verify-email-update"
        return try await performRequest(url: url, method: .post, parameters: request)
    }

    func deleteAccount() async throws -> Empty {
        let url = "\(baseURL)/user/me"
        return try await performRequest(url: url, method: .delete)
    }

    func createSupport(request: SupportRequest) async throws -> Empty {
        let url = "\(baseURL)/user/support"
        return try await performRequest(url: url, method: .post, parameters: request)
    }
    
    
    // MARK: - Generic Request Helper
    private func performRequest<T, P>(url: String, method: HTTPMethod, parameters: P) async throws -> T
    where T: Decodable & Sendable, P: Encodable & Sendable {
        
        if let data = try? JSONEncoder().encode(parameters), let body = String(data: data, encoding: .utf8) {
             print("DEBUG: [\(method.rawValue)] \(url)")
             print("DEBUG: [REQUEST BODY] \(body)")
        }

        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url,
                       method: method,
                       parameters: parameters,
                       encoder: JSONParameterEncoder.default,
                       headers: buildHeaders())
            .validate()
            .responseData { response in
                // Detailed Logging
                print("DEBUG: [\(method.rawValue)] \(url)")
                if let data = response.data, let body = String(data: data, encoding: .utf8) {
                    print("DEBUG: Response Code: \(response.response?.statusCode ?? 0)")
                    print("DEBUG: Response Body: \(body)")
                }

                switch response.result {
                case .success(let data):
                    do {
                        let decoded = try JSONDecoder().decode(T.self, from: data)
                        continuation.resume(returning: decoded)
                    } catch {
                        print("ERROR: Decoding error for \(T.self): \(error)")
                        continuation.resume(throwing: NetworkError.serverError(message: "Sunucu yanıtı çözümlenemedi."))
                    }
                case .failure(let afError):
                    print("ERROR: Request failed with error: \(afError.localizedDescription)")
                    if let data = response.data {
                        // 1) Önce { "errors": [ ... ] }
                        if let arrayError = try? JSONDecoder().decode(ErrorArrayResponse.self, from: data),
                           let first = arrayError.errors.first, !first.isEmpty {
                            continuation.resume(throwing: NetworkError.serverError(message: first))
                            return
                        }
                        // 2) Sonra { message, error }
                        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                            let message = errorResponse.message ?? errorResponse.error ?? afError.localizedDescription
                            continuation.resume(throwing: NetworkError.serverError(message: message))
                        } else {
                            let raw = String(data: data, encoding: .utf8) ?? afError.localizedDescription
                            continuation.resume(throwing: NetworkError.serverError(message: raw))
                        }
                    } else {
                        continuation.resume(throwing: NetworkError.serverError(message: afError.localizedDescription))
                    }
                }
            }
        }
    }
    
    // Overload for requests without a body (e.g., GET /user/me)
    private func performRequest<T>(url: String, method: HTTPMethod) async throws -> T where T: Decodable & Sendable {
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url,
                       method: method,
                       headers: buildHeaders()) // Authorization header handled globally
            .validate()
            .responseData { response in
                // Detailed Logging
                print("DEBUG: [\(method.rawValue)] \(url)")
                if let data = response.data, let body = String(data: data, encoding: .utf8) {
                    print("DEBUG: Response Code: \(response.response?.statusCode ?? 0)")
                    print("DEBUG: Response Body: \(body)")
                }

                switch response.result {
                case .success(let data):
                    do {
                        let decoded = try JSONDecoder().decode(T.self, from: data)
                        continuation.resume(returning: decoded)
                    } catch {
                        print("ERROR: Decoding error for \(T.self): \(error)")
                        continuation.resume(throwing: NetworkError.serverError(message: "Sunucu yanıtı çözümlenemedi."))
                    }
                case .failure(let afError):
                    print("ERROR: Request failed with error: \(afError.localizedDescription)")
                    if let data = response.data {
                        if let arrayError = try? JSONDecoder().decode(ErrorArrayResponse.self, from: data),
                           let first = arrayError.errors.first, !first.isEmpty {
                            continuation.resume(throwing: NetworkError.serverError(message: first))
                            return
                        }
                        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                            let message = errorResponse.message ?? errorResponse.error ?? afError.localizedDescription
                            continuation.resume(throwing: NetworkError.serverError(message: message))
                        } else {
                            let raw = String(data: data, encoding: .utf8) ?? afError.localizedDescription
                            continuation.resume(throwing: NetworkError.serverError(message: raw))
                        }
                    } else {
                        continuation.resume(throwing: NetworkError.serverError(message: afError.localizedDescription))
                    }
                }
            }
        }
    }
}

// Google'ın giriş ekranını sunabilmesi için bir extension
@MainActor
extension UIApplication {
    func topViewController() async -> UIViewController? {
        let keyWindow = self.connectedScenes
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)
        
        var topController = keyWindow?.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}

