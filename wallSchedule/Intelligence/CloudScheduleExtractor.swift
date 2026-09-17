import UIKit

// OpenAI-compatible /chat/completions with an image_url content part — works against
// OpenAI itself and most compatible proxies/self-hosted servers alike.
enum CloudScheduleExtractor {
    enum CloudError: Error {
        case notConfigured
        case invalidEndpoint
        case http(Int)
        case invalidResponse
    }

    private struct ChatRequest: Encodable {
        struct Message: Encodable {
            struct ContentPart: Encodable {
                struct ImageURL: Encodable { let url: String }

                let type: String
                let text: String?
                let imageURL: ImageURL?

                enum CodingKeys: String, CodingKey {
                    case type, text
                    case imageURL = "image_url"
                }
            }
            let role: String
            let content: [ContentPart]
        }
        let model: String
        let messages: [Message]
        let temperature: Double
    }

    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String }
            let message: Message
        }
        let choices: [Choice]
    }

    private struct ScheduleDTO: Decodable {
        struct LessonDTO: Decodable {
            let index: Int
            let subject: String
            let room: String
        }
        let lessons: [LessonDTO]
    }

    static func extractSchedule(from image: UIImage, targetClassName: String?) async throws -> [ManualLessonEntry] {
        let config = CloudModelConfig.load()
        guard config.isConfigured, let apiKey = CloudAPIKeyStore.load() else {
            throw CloudError.notConfigured
        }
        guard let jpeg = image.jpegData(compressionQuality: 0.8) else {
            throw CloudError.invalidResponse
        }
        let base64 = jpeg.base64EncodedString()

        let userText = if let targetClassName {
            "На фотографии объявление об изменениях в расписании, возможно для нескольких классов. Верни только уроки класса \"\(targetClassName)\", уроки остальных классов не включай. Сохраняй порядок по времени."
        } else {
            "На фотографии объявление об изменениях в расписании на сегодня. Верни список уроков по порядку."
        }

        let request = ChatRequest(
            model: config.model,
            messages: [
                .init(role: "system", content: [.init(type: "text", text: Self.systemPrompt, imageURL: nil)]),
                .init(role: "user", content: [
                    .init(type: "text", text: userText, imageURL: nil),
                    .init(type: "image_url", text: nil, imageURL: .init(url: "data:image/jpeg;base64,\(base64)")),
                ]),
            ],
            temperature: 0
        )

        var urlRequest = URLRequest(url: try endpointURL(base: config.endpoint))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            throw CloudError.http((response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content,
              let jsonData = stripCodeFence(content).data(using: .utf8) else {
            throw CloudError.invalidResponse
        }

        let schedule = try JSONDecoder().decode(ScheduleDTO.self, from: jsonData)
        return schedule.lessons
            .sorted { $0.index < $1.index }
            .map { ManualLessonEntry(subject: $0.subject, room: $0.room) }
    }

    private static let systemPrompt = """
    Ты распознаёшь школьное расписание по фотографии. Отвечай ТОЛЬКО валидным JSON без markdown-разметки и пояснений, строго в формате {"lessons":[{"index":1,"subject":"...","room":"..."}]}.
    Поле room — только идентификатор кабинета (число или сокращение вроде «с/з», «акт.зал»). НИКОГДА не добавляй туда имена учителей, номера групп или название предмета. Если кабинет не указан — пустая строка.
    Кабинет не всегда число — переписывай сокращения точно как на фото, не превращай их в число.
    Если у урока две группы с двумя кабинетами (формат «Учитель1:1 Учитель2:2» с кабинетами через «/»), укажи оба кабинета в room через « / », не выбирай один наугад и не добавляй туда имена учителей.
    """

    private static func endpointURL(base: String) throws -> URL {
        var trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("/") { trimmed.removeLast() }
        guard let url = URL(string: "\(trimmed)/chat/completions") else { throw CloudError.invalidEndpoint }
        return url
    }

    private static func stripCodeFence(_ text: String) -> String {
        var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.hasPrefix("```") else { return t }
        let parts = t.components(separatedBy: "```")
        if parts.count >= 2 { t = parts[1] }
        if t.hasPrefix("json") { t.removeFirst(4) }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
