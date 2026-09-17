import AppIntents
import UniformTypeIdentifiers

struct GetWallpaperIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Wallpaper"

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let lessons = try await AuthEduClient.shared.todaySchedule()
        let settings = RenderSettings.load()
        guard let png = await ScheduleImageRenderer.renderPNG(lessons: lessons, settings: settings) else {
            throw GetWallpaperIntentError.renderFailed
        }
        let file = IntentFile(data: png, filename: "wallpaper.png", type: .png)
        return .result(value: file)
    }
}

enum GetWallpaperIntentError: Error, CustomLocalizedStringResourceConvertible {
    case renderFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .renderFailed: "Could not render the wallpaper image"
        }
    }
}
