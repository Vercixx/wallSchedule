enum TokenStore {
    private static let account = "authedu-bearer-token"

    static func save(_ token: String) { KeychainStore.save(token, account: account) }
    static func load() -> String? { KeychainStore.load(account: account) }
    static func clear() { KeychainStore.clear(account: account) }
}
