import UIKit

// OpenAI-compatible /chat/completions with an image_url content part — works against
// OpenAI itself and most compatible proxies/self-hosted servers alike.
enum CloudScheduleExtractor {
    enum CloudError: Error, LocalizedError {
        case missingEndpoint
        case missingModel
        case missingAPIKey
        case invalidEndpoint
        case http(Int, String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .missingEndpoint: "Не указан адрес облачной модели в настройках"
            case .missingModel: "Не указано название модели в настройках"
            case .missingAPIKey: "Не указан API-ключ в настройках"
            case .invalidEndpoint: "Некорректный адрес облачной модели"
            case .http(let code, let body): "Сервер вернул ошибку \(code): \(body)"
            case .invalidResponse: "Не удалось разобрать ответ модели"
            }
        }
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

    // Providers disagree on shape: `{"error": "text"}` vs `{"error": {"message": "text"}}`.
    private struct ErrorEnvelope: Decodable {
        enum ErrorValue: Decodable {
            case text(String)
            case object(message: String?)

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let string = try? container.decode(String.self) {
                    self = .text(string)
                } else {
                    struct Nested: Decodable { let message: String? }
                    self = .object(message: try container.decode(Nested.self).message)
                }
            }

            var message: String {
                switch self {
                case .text(let string): string
                case .object(let message): message ?? "неизвестная ошибка"
                }
            }
        }

        let success: Bool?
        let error: ErrorValue?
    }

    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String? }
            let message: Message
        }
        let choices: [Choice]
    }

    // Fields declared optional on purpose — a free/small model can emit JSON null
    // for a field it isn't sure about instead of following the "empty string" instruction.
    private struct ScheduleDTO: Decodable {
        struct LessonDTO: Decodable {
            let index: Int?
            let subject: String?
            let room: String?
        }
        let lessons: [LessonDTO]
    }

    static func extractSchedule(from image: UIImage, targetClassName: String?) async throws -> [ManualLessonEntry] {
        let endpoint = CloudModelConfig.load().endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = CloudModelConfig.load().model.trimmingCharacters(in: .whitespacesAndNewlines)
        let apiKey = (CloudAPIKeyStore.load() ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !endpoint.isEmpty else { throw CloudError.missingEndpoint }
        guard !model.isEmpty else { throw CloudError.missingModel }
        guard !apiKey.isEmpty else { throw CloudError.missingAPIKey }

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
            model: model,
            messages: [
                .init(role: "system", content: [.init(type: "text", text: Self.systemPrompt, imageURL: nil)]),
                .init(role: "user", content: [
                    .init(type: "text", text: userText, imageURL: nil),
                    .init(type: "image_url", text: nil, imageURL: .init(url: "data:image/jpeg;base64,\(base64)")),
                ]),
            ],
            temperature: 0
        )

        var urlRequest = URLRequest(url: try endpointURL(base: endpoint))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("https://github.com/Vercixx/wallSchedule", forHTTPHeaderField: "HTTP-Referer")
        urlRequest.setValue("wallSchedule", forHTTPHeaderField: "X-Title")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

        // Some gateways (confirmed: seen via mitmproxy) wrap an error in an HTTP 200 —
        // check for an error envelope before assuming a low status code means success.
        if let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data),
           envelope.success == false || envelope.error != nil {
            throw CloudError.http(statusCode, envelope.error?.message ?? "провайдер вернул ошибку")
        }
        guard statusCode < 400 else {
            let body = String(data: data.prefix(500), encoding: .utf8) ?? ""
            throw CloudError.http(statusCode, body)
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content,
              !content.isEmpty,
              let jsonData = stripCodeFence(content).data(using: .utf8),
              !jsonData.isEmpty else {
            throw CloudError.invalidResponse
        }

        let schedule = try JSONDecoder().decode(ScheduleDTO.self, from: jsonData)
        return schedule.lessons
            .enumerated()
            .sorted { ($0.element.index ?? $0.offset) < ($1.element.index ?? $1.offset) }
            .map { ManualLessonEntry(subject: $0.element.subject ?? "", room: $0.element.room ?? "") }
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
