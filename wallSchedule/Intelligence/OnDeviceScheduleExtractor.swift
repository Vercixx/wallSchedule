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
    @Guide(description: "Кабинет дословно как на фото: число или сокращение (с/з, акт.зал и т.п.). НИКОГДА не добавляй в это поле имена учителей, названия предметов или номера групп — только кабинет. Если у урока два кабинета для двух групп, укажи оба через « / »")
    let room: String
}

@available(iOS 27, *)
@Generable
struct ExtractedSchedule {
    let lessons: [ExtractedLesson]
}

@available(iOS 27, *)
enum OnDeviceScheduleExtractor {
    enum ExtractError: Error, LocalizedError {
        case modelUnavailable

        var errorDescription: String? {
            "Модель на устройстве недоступна (проверьте Apple Intelligence в настройках iOS)"
        }
    }

    static func extractSchedule(from image: UIImage, targetClassName: String?) async throws -> [ManualLessonEntry] {
        guard SystemLanguageModel.default.availability == .available else {
            throw ExtractError.modelUnavailable
        }

        let commonRules = "Кабинет под названием предмета не всегда число — часто это сокращение (с/з — спортзал, акт.зал — актовый зал и т.п.), переписывай его точно как на фото. НИКОГДА не пиши в поле кабинета имена учителей — только сам кабинет. Если у урока указаны две группы с двумя учителями и двумя кабинетами (обычно английский или физкультура, формат «Учитель1:1 Учитель2:2» с кабинетами через «/»), укажи оба кабинета через « / », не выбирай один наугад и не добавляй туда имена учителей."

        let instructions = if let targetClassName {
            "На фотографии объявление об изменениях в расписании. На нём может быть расписание нескольких классов. Выбери и верни только уроки класса \"\(targetClassName)\", уроки остальных классов игнорируй. Сохраняй порядок уроков по времени. \(commonRules)"
        } else {
            "На фотографии объявление об изменениях в расписании на сегодня. Верни список уроков по порядку. \(commonRules)"
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
