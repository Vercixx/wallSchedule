import Foundation

enum FriendsStore {
    private static let defaultsKey = "wallSchedule.friends.v1"

    static func load() -> [FriendSchedule] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let friends = try? JSONDecoder().decode([FriendSchedule].self, from: data) else {
            return []
        }
        return friends
    }

    static func save(_ friends: [FriendSchedule]) {
        guard let data = try? JSONEncoder().encode(friends) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
