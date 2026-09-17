import AppIntents
import UniformTypeIdentifiers

struct GetWallpaperIntent: AppIntent {
    static let title: LocalizedStringResource = "Получить обои"

    @Parameter(title: "Кому")
    var source: ScheduleSourceEntity

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let lessons = try await lessons(for: source)
        let settings = RenderSettings.load()
        guard let png = await ScheduleImageRenderer.renderPNG(lessons: lessons, settings: settings) else {
            throw GetWallpaperIntentError.renderFailed
        }
        let file = IntentFile(data: png, filename: "wallpaper.png", type: .png)
        return .result(value: file)
    }

    private func lessons(for source: ScheduleSourceEntity) async throws -> [Lesson] {
        guard source.id != ScheduleSourceEntity.meID else {
            return try await AuthEduClient.shared.todaySchedule()
        }
        guard let uuid = UUID(uuidString: source.id),
              let schoolClass = FriendsStore.load().first(where: { $0.id == uuid }) else {
            throw GetWallpaperIntentError.classNotFound
        }
        return schoolClass.todayLessons()
    }
}

enum GetWallpaperIntentError: Error, CustomLocalizedStringResourceConvertible {
    case renderFailed
    case classNotFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .renderFailed: "Не удалось создать изображение обоев"
        case .classNotFound: "Этот класс был удалён из приложения"
        }
    }
}
