import Foundation

struct ScheduleCacheState: Codable {
    var lessons: [Lesson]
    var lastFetchAt: Date
    var fetchCountOnLastFetchDay: Int
}

// Automatic (Shortcuts-triggered) fetches are capped hard, not tunable per call —
// a ban risks the user's real school account, a stale cached schedule does not.
actor ScheduleCache {
    static let shared = ScheduleCache()

    private static let dailyCap = 2
    private static let minimumInterval: TimeInterval = 6 * 3600
    private static let moscow: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Moscow")!
        return cal
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("schedule-cache.json")
    }

    func load() -> ScheduleCacheState? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? Self.decoder.decode(ScheduleCacheState.self, from: data)
    }

    func canFetchNow(now: Date = Date()) -> Bool {
        guard let state = load() else { return true }
        let sameDay = Self.moscow.isDate(state.lastFetchAt, inSameDayAs: now)
        let countToday = sameDay ? state.fetchCountOnLastFetchDay : 0
        let intervalOK = now.timeIntervalSince(state.lastFetchAt) >= Self.minimumInterval
        return countToday < Self.dailyCap && intervalOK
    }

    func recordFetch(lessons: [Lesson], now: Date = Date()) {
        let previous = load()
        let sameDay = previous.map { Self.moscow.isDate($0.lastFetchAt, inSameDayAs: now) } ?? false
        let newCount = (sameDay ? previous!.fetchCountOnLastFetchDay : 0) + 1
        let state = ScheduleCacheState(
            lessons: lessons,
            lastFetchAt: now,
            fetchCountOnLastFetchDay: newCount
        )
        guard let data = try? Self.encoder.encode(state) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
