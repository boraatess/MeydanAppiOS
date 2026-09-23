import Foundation

@MainActor
final class AppMemoryCache {
    static let shared = AppMemoryCache()

    private struct Entry {
        let value: Any
        let createdAt: Date
    }

    private var storage: [String: Entry] = [:]

    private init() {}

    func value<T>(forKey key: String, maxAge: TimeInterval) -> T? {
        guard let entry = storage[key] else { return nil }

        if Date().timeIntervalSince(entry.createdAt) > maxAge {
            storage.removeValue(forKey: key)
            return nil
        }

        return entry.value as? T
    }

    func set<T>(_ value: T, forKey key: String) {
        storage[key] = Entry(value: value, createdAt: Date())
    }

    func removeValue(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    func removeAll() {
        storage.removeAll()
    }
}
