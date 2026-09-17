import SwiftUI

struct RenderSettings: Codable, Equatable {
    var backgroundHex: String = "#000000"
    var textHex: String = "#FFFFFF"

    var backgroundColor: Color { Color(hex: backgroundHex) }
    var textColor: Color { Color(hex: textHex) }

    private static let defaultsKey = "wallSchedule.renderSettings.v1"

    static func load() -> RenderSettings {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let settings = try? JSONDecoder().decode(RenderSettings.self, from: data) else {
            return RenderSettings()
        }
        return settings
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
