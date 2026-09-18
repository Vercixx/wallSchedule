import Foundation

enum MyClassStore {
    private static let defaultsKey = "wallSchedule.myClass.v1"

    static func load() -> FriendSchedule? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let schedule = try? JSONDecoder().decode(FriendSchedule.self, from: data) else {
            return nil
        }
        return schedule
    }

    static func save(_ schedule: FriendSchedule) {
        guard let data = try? JSONEncoder().encode(schedule) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
