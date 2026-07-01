import Foundation
import Alamofire

@MainActor
class InterestsViewModel: ObservableObject {
    
    @Published var interests: [Interest] = []
    @Published var selectedInterests: Set<Interest> = []
    @Published var isLoading: Bool = false
    @Published var submitErrorMessage: String? = nil
    private let hobbiesService: HobbiesServiceProtocol
    private let appFlowState: AppFlowState
    
    init(hobbiesService: HobbiesServiceProtocol = HobbiesService(baseURL: AppConfig.apiBaseURL), appFlowState: AppFlowState) {
        self.hobbiesService = hobbiesService
        self.appFlowState = appFlowState
        Task { [weak self] in
            await self?.fetchInterests()
        }
    }
    
    func toggleInterestSelection(_ interest: Interest) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }
    
    func completeOnboarding() {
        print("İlgi alanı seçimi tamamlandı!")
        print("Seçilen ilgi alanları: \(selectedInterests.map { $0.name })")
        // TODO: Bu verileri API'ye gönder ve kullanıcıyı ana ekrana (MainTabView) yönlendir.
    }
    
    func submitSelectedInterests(authManager: AuthenticationManager) async {
        guard !selectedInterests.isEmpty else { return }
        isLoading = true
        submitErrorMessage = nil
        defer { isLoading = false }
        
        guard let token = authManager.currentToken(), !token.isEmpty else {
            let msg = "Token bulunamadı. Kullanıcı yetkisiz."
            print(msg)
            submitErrorMessage = msg
            return
        }
        
        let hobbyIDs = selectedInterests.map { $0.id }
        let request = SetHobbiesRequest(hobbies: hobbyIDs)
        
        do {
            _ = try await hobbiesService.setHobbies(request: request, token: token)
            print("İlgi alanları başarıyla güncellendi.")
            appFlowState.navigate(to: .main)
        } catch let error as NetworkError {
            switch error {
            case .invalidURL:
                let msg = "Geçersiz API adresi."
                print("Sunucu hatası (invalidURL): \(msg)")
                submitErrorMessage = msg
            case .decodingFailed(let decodeError):
                let msg = "Sunucu yanıtı çözümlenemedi: \(decodeError.localizedDescription)"
                print("Sunucu hatası (decodingFailed): \(msg)")
                submitErrorMessage = msg
            case .serverError(let message):
                print("Sunucu hatası (serverError): \(message)")
                submitErrorMessage = message
            case .unknown(let underlying):
                let msg = underlying.localizedDescription
                print("Sunucu hatası (unknown): \(msg)")
                submitErrorMessage = msg
            }
        } catch {
            let msg = "İstek gönderilirken hata: \(error.localizedDescription)"
            print(msg)
            submitErrorMessage = msg
        }
    }
    
    private func fetchInterests() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let api = try await hobbiesService.fetchAllHobbies()
            // Deterministic color assignment: cycle through palette to avoid adjacent duplicates
            let palette = Interest.colorPalette
            let mapped: [Interest] = api.hobbies.enumerated().map { index, hobby in
                let color = palette.isEmpty ? .gray : palette[index % palette.count]
                return Interest(id: hobby._id, name: hobby.name, color: color)
            }
            self.interests = mapped
        } catch let error as NetworkError {
            print("Hobiler alınırken sunucu hatası: \(error.localizedDescription)")
        } catch {
            print("Hobiler alınırken hata: \(error.localizedDescription)")
        }
    }
}

