import SwiftUI
import UIKit

struct RenderSettings: Codable, Equatable {
    var backgroundHex: String = "#000000"
    var textHex: String = "#FFFFFF"
    var fontFamily: String = SystemFonts.systemSentinel
    var textSize: Double = 34

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

enum SystemFonts {
    static let systemSentinel = "Системный"

    static var familyNames: [String] {
        [systemSentinel] + UIFont.familyNames.sorted()
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

    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
