import FoundationModels
import UIKit

// FoundationModels API surface recalled from docs, unverified against a real build.
// Image-attachment prompting is an iOS 27 capability (Attachment type), not iOS 26.
@available(iOS 27, *)
@Generable
struct ExtractedLesson {
    @Guide(description: "Порядковый номер урока по расписанию, начиная с 1")
    let index: Int
    @Guide(description: "Название предмета урока")
    let subject: String
    @Guide(description: "Номер или название кабинета, если указан, иначе пустая строка")
    let room: String
}

@available(iOS 27, *)
@Generable
struct ExtractedSchedule {
    let lessons: [ExtractedLesson]
}

@available(iOS 27, *)
enum ScheduleExtractor {
    enum ExtractError: Error {
        case modelUnavailable
    }

    static func extractSchedule(from image: UIImage, targetClassName: String?) async throws -> [ManualLessonEntry] {
        guard SystemLanguageModel.default.availability == .available else {
            throw ExtractError.modelUnavailable
        }

        let instructions = if let targetClassName {
            "На фотографии объявление об изменениях в расписании. На нём может быть расписание нескольких классов. Выбери и верни только уроки класса \"\(targetClassName)\", уроки остальных классов игнорируй. Сохраняй порядок уроков по времени."
        } else {
            "На фотографии объявление об изменениях в расписании на сегодня. Верни список уроков по порядку."
        }

        let prompt = Prompt {
            instructions
            Attachment(image)
        }

        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt, generating: ExtractedSchedule.self)

        return response.content.lessons
            .sorted { $0.index < $1.index }
            .map { ManualLessonEntry(subject: $0.subject, room: $0.room) }
    }
}
