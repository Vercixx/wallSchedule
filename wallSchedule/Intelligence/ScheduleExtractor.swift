import FoundationModels

// FoundationModels API surface recalled from docs, unverified against a real build.
@available(iOS 26, *)
@Generable
struct ExtractedLesson {
    @Guide(description: "Порядковый номер урока по расписанию, начиная с 1")
    let index: Int
    @Guide(description: "Название предмета урока")
    let subject: String
    @Guide(description: "Номер или название кабинета, если указан, иначе пустая строка")
    let room: String
}

@available(iOS 26, *)
@Generable
struct ExtractedSchedule {
    let lessons: [ExtractedLesson]
}

@available(iOS 26, *)
enum ScheduleExtractor {
    enum ExtractError: Error {
        case modelUnavailable
    }

    static func extractSchedule(from ocrText: String, targetClassName: String?) async throws -> [ManualLessonEntry] {
        guard SystemLanguageModel.default.availability == .available else {
            throw ExtractError.modelUnavailable
        }

        let instructions = if let targetClassName {
            "Ниже текст объявления об изменениях в расписании, распознанный с фотографии. На нём может быть расписание нескольких классов. Выбери и верни только уроки класса \"\(targetClassName)\", уроки остальных классов игнорируй. Сохраняй порядок уроков по времени."
        } else {
            "Ниже текст объявления об изменениях в расписании на сегодня, распознанный с фотографии. Верни список уроков по порядку."
        }

        let session = LanguageModelSession()
        let response = try await session.respond(
            to: "\(instructions)\n\nТекст объявления:\n\(ocrText)",
            generating: ExtractedSchedule.self
        )

        return response.content.lessons
            .sorted { $0.index < $1.index }
            .map { ManualLessonEntry(subject: $0.subject, room: $0.room) }
    }
}
