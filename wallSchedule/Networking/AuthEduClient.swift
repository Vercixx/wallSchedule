import Foundation

// Endpoints/headers verified against OctoDiary-py, not guessed.
// person_id/mes_role bootstrap assumes a student account is its own "child" entry — unverified against a live capture.
actor AuthEduClient {
    static let shared = AuthEduClient()

    enum ClientError: Error {
        case notLoggedIn
        case bootstrapIncomplete
        case http(Int)
        case decode
    }

    private struct Bootstrap: Codable {
        let personId: String
        let role: String
    }

    private let session = URLSession(configuration: .ephemeral)
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso = ISO8601DateFormatter()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = isoFractional.date(from: raw) ?? iso.date(from: raw) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date: \(raw)")
        }
        return d
    }()

    private static let bootstrapDefaultsKey = "wallSchedule.bootstrap.v1"
    private static let moscowTimeZone = TimeZone(identifier: "Europe/Moscow")!

    static func clearBootstrapCache() {
        UserDefaults.standard.removeObject(forKey: bootstrapDefaultsKey)
    }

    // bypassRateLimit is for the manual in-app refresh button only — never from the App Intent.
    func todaySchedule(bypassRateLimit: Bool = false) async throws -> [Lesson] {
        if !bypassRateLimit {
            guard await ScheduleCache.shared.canFetchNow() else {
                if let cached = await ScheduleCache.shared.load() { return cached.lessons }
                throw ClientError.http(429)
            }
        }

        guard let token = TokenStore.load() else { throw ClientError.notLoggedIn }

        do {
            let bootstrap = try await resolveBootstrap(token: token)
            let lessons = try await fetchTodayEvents(token: token, bootstrap: bootstrap)
            await ScheduleCache.shared.recordFetch(lessons: lessons)
            return lessons
        } catch {
            if let cached = await ScheduleCache.shared.load() { return cached.lessons }
            throw error
        }
    }

    private func resolveBootstrap(token: String) async throws -> Bootstrap {
        if let cached = Self.loadCachedBootstrap() { return cached }

        let profileInfoURL = URL(string: "https://myschool.mosreg.ru/acl/api/users/profile_info")!
        let profiles: [ProfileInfoEntry] = try await get(
            profileInfoURL,
            token: token,
            extra: ["partner-source-id": "MOBILE"]
        )
        guard let profileId = profiles.first?.id else { throw ClientError.bootstrapIncomplete }

        let familyProfileURL = URL(string: "https://api.myschool.mosreg.ru/family/mobile/v1/profile")!
        let familyProfile: FamilyProfileResponse = try await get(
            familyProfileURL,
            token: token,
            extra: [
                "x-mes-subsystem": "familymp",
                "client-type": "diary-mobile",
                "profile-id": String(profileId),
            ]
        )

        guard let personId = familyProfile.children?.first?.contingentGuid,
              let role = familyProfile.profile?.type else {
            throw ClientError.bootstrapIncomplete
        }

        let bootstrap = Bootstrap(personId: personId, role: role)
        Self.saveCachedBootstrap(bootstrap)
        return bootstrap
    }

    private func fetchTodayEvents(token: String, bootstrap: Bootstrap) async throws -> [Lesson] {
        let today = Self.moscowDateString(Date())
        var components = URLComponents(string: "https://authedu.mosreg.ru/api/eventcalendar/v1/api/events")!
        components.queryItems = [
            URLQueryItem(name: "person_ids", value: bootstrap.personId),
            URLQueryItem(name: "begin_date", value: today),
            URLQueryItem(name: "end_date", value: today),
            URLQueryItem(name: "expand", value: "marks,homework,absence_reason_id,health_status,nonattendance_reason_id"),
        ]

        let events: EventsResponse = try await get(
            components.url!,
            token: token,
            extra: [
                "x-mes-subsystem": "familymp",
                "client-type": "diary-mobile",
                "x-mes-role": bootstrap.role,
            ]
        )
        return (events.response ?? []).toLessons()
    }

    private func get<T: Decodable>(_ url: URL, token: String, extra: [String: String]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        for (key, value) in headers(token: token, extra: extra) {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw ClientError.http(code)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ClientError.decode
        }
    }

    private func headers(token: String, extra: [String: String]) -> [String: String] {
        var headers: [String: String] = [
            "User-Agent": ClientIdentity.userAgent,
            "Content-Type": "application/json",
            "Accept": "application/json, text/plain, */*",
            "Accept-Language": ClientIdentity.acceptLanguage,
            "Authorization": "Bearer \(token)",
            "Auth-Token": token,
            "Cookie": "aupdtoken=\(token); aupd_token=\(token)",
        ]
        for (key, value) in extra { headers[key] = value }
        return headers
    }

    private static func loadCachedBootstrap() -> Bootstrap? {
        guard let data = UserDefaults.standard.data(forKey: bootstrapDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(Bootstrap.self, from: data)
    }

    private static func saveCachedBootstrap(_ bootstrap: Bootstrap) {
        guard let data = try? JSONEncoder().encode(bootstrap) else { return }
        UserDefaults.standard.set(data, forKey: bootstrapDefaultsKey)
    }

    private static func moscowDateString(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = moscowTimeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year!, components.month!, components.day!)
    }
}
