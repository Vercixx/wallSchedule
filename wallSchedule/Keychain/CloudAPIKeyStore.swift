enum CloudAPIKeyStore {
    private static let account = "cloud-model-api-key"

    static func save(_ key: String) { KeychainStore.save(key, account: account) }
    static func load() -> String? { KeychainStore.load(account: account) }
    static func clear() { KeychainStore.clear(account: account) }
}
