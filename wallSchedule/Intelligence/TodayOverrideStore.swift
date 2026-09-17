import Foundation

// Same-day-only override for the user's own schedule, set by photo recognition.
// Never persists past today — next day's API fetch replaces it normally.
enum TodayOverrideStore {
    private static let key = "wallSchedule.todayOverride.v1"

    private struct Stored: Codable {
        let dateKey: String
        let lessons: [Lesson]
    }

    static func save(_ lessons: [Lesson]) {
        let stored = Stored(dateKey: AuthEduClient.moscowDateString(Date()), lessons: lessons)
        guard let data = try? JSONEncoder().encode(stored) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> [Lesson]? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode(Stored.self, from: data),
              stored.dateKey == AuthEduClient.moscowDateString(Date()) else { return nil }
        return stored.lessons
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
