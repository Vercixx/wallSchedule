import Foundation

struct ProfileInfoEntry: Decodable {
    let id: Int
    let type: String
}

struct FamilyProfileResponse: Decodable {
    struct Profile: Decodable {
        let type: String?
    }
    struct Child: Decodable {
        let contingentGuid: String?
        let className: String?

        enum CodingKeys: String, CodingKey {
            case contingentGuid = "contingent_guid"
            case className = "class_name"
        }
    }

    let profile: Profile?
    let children: [Child]?
}

struct EventsResponse: Decodable {
    struct Item: Decodable {
        let subjectName: String?
        let roomName: String?
        let roomNumber: String?
        let startAt: Date?
        let cancelled: Bool?

        enum CodingKeys: String, CodingKey {
            case subjectName = "subject_name"
            case roomName = "room_name"
            case roomNumber = "room_number"
            case startAt = "start_at"
            case cancelled
        }
    }

    let response: [Item]?
}

struct Lesson: Codable, Identifiable, Equatable {
    let index: Int
    let subject: String
    let room: String
    let startAt: Date

    var id: Int { index }

    var displayLine: String {
        "\(index). \(subject) (\(room))"
    }
}

extension EventsResponse.Item {
    func toLesson() -> Lesson? {
        guard cancelled != true, let subjectName, let startAt else { return nil }
        let room = roomName ?? roomNumber ?? "?"
        return Lesson(index: 0, subject: subjectName, room: room, startAt: startAt)
    }
}

extension Array where Element == EventsResponse.Item {
    func toLessons() -> [Lesson] {
        compactMap { $0.toLesson() }
            .sorted { $0.startAt < $1.startAt }
            .enumerated()
            .map { Lesson(index: $0.offset + 1, subject: $0.element.subject, room: $0.element.room, startAt: $0.element.startAt) }
    }
}
