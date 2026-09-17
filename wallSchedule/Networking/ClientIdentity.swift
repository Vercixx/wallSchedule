import Foundation

enum ClientIdentity {
    // Placeholder — replace with a User-Agent captured via mitmproxy/Charles from the
    // real official app if header-fingerprint parity turns out to matter in practice.
    static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

    static let acceptLanguage = "ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3"
}
