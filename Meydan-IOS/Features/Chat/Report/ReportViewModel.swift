import SwiftUI

// MARK: - ViewModel Katmanı

@MainActor
final class ReportViewModel: ObservableObject {
    // Input
    let context: ReportContext
    
    // UI Texts
    var titleText: AttributedString {
        switch context {
        case .user(_, let username):
            var str = AttributedString("@\(username) adlı kullanıcıyı şikayet ediyorsun")
            if let range = str.range(of: "@\(username)") { str[range].font = .manrope(.semiBold, size: 16) }
            return str
        case .stream(_, let owner, let title):
            var str = AttributedString("@\(owner)‘in \"\(title)\" adlı yayınını şikayet ediyorsun")
            if let ownerRange = str.range(of: "@\(owner)") { str[ownerRange].font = .manrope(.semiBold, size: 16) }
            if let titleRange = str.range(of: "\"\(title)\"") { str[titleRange].font = .manrope(.semiBold, size: 16) }
            return str
        }
    }
    
    var reasons: [ReportReasonModel] {
        switch context {
        case .user: return ReportReasonModel.userReasons
        case .stream: return ReportReasonModel.streamReasons
        }
    }
    
    // State
    @Published var selectedReason: ReportReasonModel? = nil
    @Published var descriptionText: String = ""
    @Published var descriptionHasError: Bool = false
    @Published var isSending: Bool = false
    @Published var showSuccessOverlay: Bool = false
    @Published var errorMessage: String?
    
    private let reportService: ReportServiceProtocol
    
    init(context: ReportContext, reportService: ReportServiceProtocol = ReportService.shared) {
        self.context = context
        self.reportService = reportService
    }
    
    func selectReason(_ reason: ReportReasonModel) {
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedReason = reason
        }
    }
    
    func onDescriptionChange(_ newValue: String) {
        if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            descriptionHasError = false
        }
    }
    
    func sendReport() {
        // Validasyon
        guard !isSending, !showSuccessOverlay else { return }
        errorMessage = nil
        if let warning = ContentFilter.warning(for: descriptionText) {
            errorMessage = warning
            return
        }
        guard validate() else { return }
        let reason = selectedReason ?? .other
        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        isSending = true
        
        let targetType: String
        let targetId: String
        
        switch context {
        case .user(let id, _):
            targetType = "User"
            targetId = id
        case .stream(let id, _, _):
            targetType = "Room" // Adjust this if the backend expects "Stream" or "Room"
            targetId = id
        }
        
        let request = SendReportRequest(
            targetType: targetType,
            targetId: targetId,
            reason: reason.displayText,
            description: trimmedDescription
        )
        
        Task {
            do {
                _ = try await reportService.sendReport(request: request)
                self.isSending = false
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.showSuccessOverlay = true
                }
            } catch {
                print("DEBUG: Şikayet gönderilemedi: \(error.localizedDescription)")
                self.isSending = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func validate() -> Bool {
        let hasSelectedReason = selectedReason != nil
        let hasDescription = !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if !hasSelectedReason && !hasDescription {
            withAnimation(.easeInOut(duration: 0.15)) { descriptionHasError = true }
            return false
        }
        return true
    }
}

// MARK: - Service/Repository (Geleceğe Hazır)
// Buraya gerçek ağ katmanını bağlamak için bir protokol tanımlayabilirsiniz.
// protocol ReportService {
//     func sendReport(context: ReportContext, reason: ReportReasonModel, description: String) async throws
// }
