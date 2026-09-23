import SwiftUI

struct LiveViewerCountBadge: View {
    @Environment(\.scenePhase) private var scenePhase

    let roomId: String
    let initialCount: Int

    @State private var viewerCount: Int
    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    init(roomId: String, initialCount: Int) {
        self.roomId = roomId
        self.initialCount = initialCount
        _viewerCount = State(initialValue: initialCount)
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "person")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)

            Text("\(viewerCount)")
                .font(.manrope(.bold, size: 12))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.82))
        .clipShape(Capsule())
        .task(id: roomId) {
            viewerCount = initialCount
            await refreshViewerCount()
        }
        .onReceive(refreshTimer) { _ in
            guard scenePhase == .active else { return }
            Task {
                await refreshViewerCount()
            }
        }
    }

    @MainActor
    private func refreshViewerCount() async {
        let trimmedRoomId = roomId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRoomId.isEmpty else { return }

        do {
            let response = try await RoomService.shared.fetchRoomViewers(id: trimmedRoomId)
            viewerCount = response.count ?? response.viewers.count
        } catch {
            print("DEBUG: Yayın kişi sayısı güncellenemedi: \(error.localizedDescription)")
        }
    }
}
