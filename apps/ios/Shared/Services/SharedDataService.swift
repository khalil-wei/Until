import Foundation

/// Persists CountdownEvent data in a shared App Group UserDefaults
/// so both the main app and the widget extension can access the same data.
struct SharedDataService {

    static let appGroupID = "group.com.khalil.until"
    private static let eventsKey = "countdownEvents"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func save(_ events: [CountdownEvent]) {
        guard let defaults else { return }
        do {
            let data = try JSONEncoder().encode(events)
            defaults.set(data, forKey: eventsKey)
        } catch {
            print("[SharedDataService] Save error: \(error)")
        }
    }

    static func load() -> [CountdownEvent] {
        guard let defaults,
              let data = defaults.data(forKey: eventsKey) else { return [] }
        do {
            return try JSONDecoder()
                .decode([CountdownEvent].self, from: data)
                .map { $0.normalizedForDisplay() }
        } catch {
            print("[SharedDataService] Load error: \(error)")
            return []
        }
    }
}
