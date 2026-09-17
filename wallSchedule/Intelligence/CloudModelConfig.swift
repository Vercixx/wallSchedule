import Foundation

struct CloudModelConfig: Codable, Equatable {
    var endpoint: String = ""
    var model: String = ""

    private static let defaultsKey = "wallSchedule.cloudModelConfig.v1"

    static func load() -> CloudModelConfig {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let config = try? JSONDecoder().decode(CloudModelConfig.self, from: data) else {
            return CloudModelConfig()
        }
        return config
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }

    var isConfigured: Bool {
        !endpoint.trimmingCharacters(in: .whitespaces).isEmpty
            && !model.trimmingCharacters(in: .whitespaces).isEmpty
            && CloudAPIKeyStore.load() != nil
    }
}
